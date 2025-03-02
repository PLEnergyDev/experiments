/* The Computer Language Benchmarks Game
   http://benchmarksgame.alioth.debian.org/
*/

using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using System.Runtime.InteropServices;

static class revcomp
{
    [DllImport("librapl_interface", EntryPoint = "start_rapl")]
    public static extern bool start_rapl();

    [DllImport("librapl_interface", EntryPoint = "stop_rapl")]
    public static extern void stop_rapl();

    static readonly int READER_BUFFER_SIZE = 1024 * 1024 * 16;

    static readonly byte[] comp = new byte[256];
    static readonly byte LF = 10;
    const string Seq = "ABCDGHKMRTVYabcdghkmrtvy";
    const string Rev = "TVGHCDMKYABRTVGHCDMKYABR";

    static byte[] inputData;

    public static void Main(string[] args)
    {
        using (var inS = Console.OpenStandardInput())
        {
            using (var ms = new MemoryStream())
            {
                inS.CopyTo(ms);
                inputData = ms.ToArray();
            }
        }

        int iterations = int.Parse(args[0]);
        for (int i = 0; i < iterations; i++)
        {
            initialize();
            start_rapl();
            run_benchmark();
            stop_rapl();
            cleanup();
        }
    }

    static void initialize()
    {
        InitComplements();
        RCBlock.ResetSequenceNumbers();
    }

    static void run_benchmark()
    {
        var processor = new ReverseComplementProcessor(inputData);
        processor.Process();
    }

    static void cleanup()
    {
    }

    static void InitComplements()
    {
        for (int i = 0; i < 256; i++)
        {
            comp[i] = (byte)i;
        }
        for (int i = 0; i < Seq.Length; i++)
        {
            comp[(byte)Seq[i]] = (byte)Rev[i];
        }
        comp[LF] = 0;
        comp[(byte)' '] = 0;
    }

    class ReverseComplementProcessor
    {
        byte[] inputData;

        BlockingCollection<byte[]> readQue = new BlockingCollection<byte[]>();
        BlockingCollection<RCBlock> inQue = new BlockingCollection<RCBlock>();
        BlockingCollection<RCBlock> outQue = new BlockingCollection<RCBlock>();

        public ReverseComplementProcessor(byte[] inputData)
        {
            this.inputData = inputData;
        }

        public void Process()
        {
            var readerTask = Task.Run(() => Reader());
            var parserTask = Task.Run(() => Parser());
            var reverserTask = Task.Run(() => Reverser());
            var writerTask = Task.Run(() => Writer());

            Task.WaitAll(readerTask, parserTask, reverserTask);
            outQue.CompleteAdding();
            writerTask.Wait();
        }

        void Reader()
        {
            int offset = 0;
            int totalLength = inputData.Length;

            while (offset < totalLength)
            {
                int bytesToRead = Math.Min(READER_BUFFER_SIZE, totalLength - offset);
                byte[] buffer = new byte[bytesToRead];
                Buffer.BlockCopy(inputData, offset, buffer, 0, bytesToRead);
                offset += bytesToRead;
                readQue.Add(buffer);
            }
            readQue.CompleteAdding();
        }

        void Parser()
        {
            var rdr = new RCBlockReader(readQue);
            RCBlock rcBlock;
            while ((rcBlock = rdr.Read()) != null)
            {
                inQue.Add(rcBlock);
            }
            inQue.CompleteAdding();
        }

        void Reverser()
        {
            try
            {
                foreach (var block in inQue.GetConsumingEnumerable())
                {
                    block.ReverseAndComplement();
                    outQue.Add(block);
                }
            }
            catch (InvalidOperationException) { }
        }

        void Writer()
        {
            using (var outS = Console.OpenStandardOutput())
            {
                try
                {
                    foreach (var block in outQue.GetConsumingEnumerable())
                    {
                        block.Write(outS);
                    }
                }
                catch (InvalidOperationException) { }
            }
        }
    }

    class RCBlock
    {
        static int nextSequenceNumberToOutput = 0;
        static int sequenceNumberGenerator = 0;
        static readonly object lockObj = new object();

        public int SequenceNumber;

        public List<byte[]> Title;
        public List<byte[]> Data;
        public byte[] FlatData;
        public byte[] FlatTitle;

        public static void ResetSequenceNumbers()
        {
            nextSequenceNumberToOutput = 0;
            sequenceNumberGenerator = 0;
        }

        internal void ReverseAndComplement()
        {
            var flattenTitleTask = Task.Run(() => FlattenTitle());
            var flattenDataTask = Task.Run(() => FlattenData());
            Task.WaitAll(flattenTitleTask, flattenDataTask);

            int i = 0, j = FlatData.Length - 1;
            byte ci, cj;

            while (i < j)
            {
                ci = FlatData[i];
                if (ci == LF)
                {
                    i++;
                    continue;
                }
                cj = FlatData[j];
                if (cj == LF)
                {
                    j--;
                    continue;
                }
                FlatData[i] = comp[cj];
                FlatData[j] = comp[ci];
                i++;
                j--;
            }
            if (i == j && FlatData[i] != LF)
            {
                FlatData[i] = comp[FlatData[i]];
            }
        }

        void FlattenTitle()
        {
            FlatTitle = FlattenList(Title);
        }

        void FlattenData()
        {
            FlatData = FlattenList(Data);
        }

        internal void Write(Stream s)
        {
            lock (lockObj)
            {
                while (SequenceNumber != nextSequenceNumberToOutput)
                {
                    Monitor.Wait(lockObj);
                }

                s.Write(FlatTitle, 0, FlatTitle.Length);
                s.WriteByte(LF);
                s.Write(FlatData, 0, FlatData.Length);

                nextSequenceNumberToOutput++;
                Monitor.PulseAll(lockObj);
            }
        }

        static byte[] FlattenList(List<byte[]> lineBuffer)
        {
            int totalSize = 0;
            foreach (var arr in lineBuffer)
            {
                totalSize += arr.Length;
            }

            byte[] result = new byte[totalSize];
            int pos = 0;

            foreach (var arr in lineBuffer)
            {
                Buffer.BlockCopy(arr, 0, result, pos, arr.Length);
                pos += arr.Length;
            }

            return result;
        }

        public static int GetNextSequenceNumber()
        {
            return Interlocked.Increment(ref sequenceNumberGenerator) - 1;
        }
    }

    class RCBlockReader
    {
        BlockingCollection<byte[]> readQue;
        static readonly byte GT = (byte)'>';
        byte[] byteBuffer;
        int bytePos, bytesRead;

        public RCBlockReader(BlockingCollection<byte[]> readQue)
        {
            this.readQue = readQue;
        }

        public RCBlock Read()
        {
            var title = ReadLine(LF);
            if (title == null)
            {
                return null;
            }

            var data = ReadUntilNextTitle();
            var block = new RCBlock
            {
                Title = title,
                Data = data,
                SequenceNumber = RCBlock.GetNextSequenceNumber()
            };
            return block;
        }

        private List<byte[]> ReadLine(byte lineSeparator)
        {
            if (bytePos == bytesRead && ReadToBuffer() == 0)
            {
                return null;
            }
            if (bytesRead == 0) return null;

            List<byte[]> lineBuffer = null;
            int num;
            byte c;

            while (true)
            {
                num = bytePos;
                do
                {
                    if (num >= bytesRead)
                        break;
                    c = byteBuffer[num];
                    if (c == lineSeparator)
                    {
                        int length = num - bytePos;
                        byte[] result = new byte[length];
                        Buffer.BlockCopy(byteBuffer, bytePos, result, 0, length);
                        bytePos = num + 1;

                        if (lineBuffer != null)
                        {
                            lineBuffer.Add(result);
                        }
                        else
                        {
                            lineBuffer = new List<byte[]> { result };
                        }
                        return lineBuffer;
                    }
                    num++;
                } while (num < bytesRead);

                int remaining = bytesRead - bytePos;
                if (lineBuffer == null)
                {
                    lineBuffer = new List<byte[]>();
                }
                byte[] tmp = new byte[remaining];
                Buffer.BlockCopy(byteBuffer, bytePos, tmp, 0, remaining);

                lineBuffer.Add(tmp);
                if (ReadToBuffer() <= 0)
                {
                    return lineBuffer;
                }
            }
        }

        private List<byte[]> ReadUntilNextTitle()
        {
            List<byte[]> dataBuffer = new List<byte[]>();

            while (true)
            {
                if (bytePos == bytesRead && ReadToBuffer() == 0)
                {
                    break;
                }

                int num = bytePos;
                while (num < bytesRead)
                {
                    if (byteBuffer[num] == GT && num == bytePos)
                    {
                        return dataBuffer;
                    }
                    num++;
                }

                int length = num - bytePos;
                byte[] dataChunk = new byte[length];
                Buffer.BlockCopy(byteBuffer, bytePos, dataChunk, 0, length);
                dataBuffer.Add(dataChunk);
                bytePos = num;
            }

            return dataBuffer;
        }

        private int ReadToBuffer()
        {
            try
            {
                byteBuffer = readQue.Take();
                bytePos = 0;
                bytesRead = byteBuffer.Length;
                return bytesRead;
            }
            catch (InvalidOperationException)
            {
                byteBuffer = null;
                bytesRead = 0;
                return 0;
            }
        }
    }
}
