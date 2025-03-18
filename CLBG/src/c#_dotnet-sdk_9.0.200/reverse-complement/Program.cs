// The Computer Language Benchmarks Game
// https://benchmarksgame-team.pages.debian.net/benchmarksgame/

// ported from F# version with improvements by Anthony Lloyd

using System;
using System.IO;
using System.Buffers;
using System.Threading;

using System.Runtime.InteropServices;

static class ReverseComplement
{
    [DllImport("librapl_interface", EntryPoint = "start_rapl")]
    private static extern bool start_rapl();

    [DllImport("librapl_interface", EntryPoint = "stop_rapl")]
    private static extern void stop_rapl();

    const int PAGE_SIZE = 1024 * 1024;
    const byte LF = (byte)'\n', GT = (byte)'>';
    static volatile int readCount = 0, lastPageSize = PAGE_SIZE, canWriteCount = 0;
    static byte[][] pages = new byte[1024][];

    public static void Main()
    {
        // Read the input data once at the start
        byte[] inputData;
        using (var ms = new MemoryStream())
        {
            Console.OpenStandardInput().CopyTo(ms);
            inputData = ms.ToArray();
        }

        while (true)
        {
            initialize();
            if (!start_rapl()) break;
            run_benchmark(inputData);
            stop_rapl();
        }
    }

    private static void initialize()
    {
        // Reset all static variables for a fresh run
        readCount = 0;
        lastPageSize = PAGE_SIZE;
        canWriteCount = 0;
        pages = new byte[1024][];
    }

    private static void run_benchmark(byte[] inputData)
    {
        new Thread(() =>
        {
            static int Read(Stream stream, byte[] bytes, int offset)
            {
                var bytesRead = stream.Read(bytes, offset, PAGE_SIZE - offset);
                return bytesRead + offset == PAGE_SIZE ? PAGE_SIZE
                        : bytesRead == 0 ? offset
                        : Read(stream, bytes, offset + bytesRead);
            }
            
            using var inStream = new BufferedStream(new MemoryStream(inputData));
            do
            {
                var page = ArrayPool<byte>.Shared.Rent(PAGE_SIZE);
                lastPageSize = Read(inStream, page, 0);
                pages[readCount] = page;
                readCount++;
            } while (lastPageSize == PAGE_SIZE);
        }).Start();

        new Thread(() =>
        {
            static void Reverse(object o)
            {
                Span<byte> map = stackalloc byte[256];
                for (int b = 0; b < map.Length; b++) map[b] = (byte)b;
                map['A'] = map['a'] = (byte)'T';
                map['B'] = map['b'] = (byte)'V';
                map['C'] = map['c'] = (byte)'G';
                map['D'] = map['d'] = (byte)'H';
                map['G'] = map['g'] = (byte)'C';
                map['H'] = map['h'] = (byte)'D';
                map['K'] = map['k'] = (byte)'M';
                map['M'] = map['m'] = (byte)'K';
                map['R'] = map['r'] = (byte)'Y';
                map['T'] = map['t'] = (byte)'A';
                map['V'] = map['v'] = (byte)'B';
                map['Y'] = map['y'] = (byte)'R';
                var (loPageID, lo, lastPageID, hi, previous) =
                    ((int, int, int, int, Thread))o;
                var hiPageID = lastPageID;
                if (lo == PAGE_SIZE) { lo = 0; loPageID++; }
                if (hi == -1) { hi = PAGE_SIZE - 1; hiPageID--; }
                var loPage = pages[loPageID];
                var hiPage = pages[hiPageID];
                do
                {
                    ref var loValue = ref loPage[lo++];
                    ref var hiValue = ref hiPage[hi--];
                    if (loValue == LF)
                    {
                        if (hiValue != LF) hi++;
                    }
                    else if (hiValue == LF)
                    {
                        lo--;
                    }
                    else
                    {
                        var swap = map[loValue];
                        loValue = map[hiValue];
                        hiValue = swap;
                    }
                    if (lo == PAGE_SIZE)
                    {
                        lo = 0;
                        loPage = pages[++loPageID];
                        if (previous == null || !previous.IsAlive)
                            canWriteCount = loPageID;
                    }
                    if (hi == -1)
                    {
                        hi = PAGE_SIZE - 1;
                        hiPage = pages[--hiPageID];
                    }
                } while (loPageID < hiPageID
                        || (loPageID == hiPageID && lo <= hi));
                previous?.Join();
                canWriteCount = lastPageID;
            }

            int pageID = 0, index = 0; Thread previous = null;
            while (true)
            {
                while (true) // skip header
                {
                    while (pageID == readCount) Thread.Sleep(0);
                    index = Array.IndexOf(pages[pageID], LF, index);
                    if (index != -1) break;
                    index = 0;
                    pageID++;
                }
                var loPageID = pageID;
                var lo = ++index;
                while (true)
                {
                    while (pageID == readCount) Thread.Sleep(0);
                    var isLastPage = pageID + 1 == readCount
                                  && lastPageSize != PAGE_SIZE;
                    index = Array.IndexOf(pages[pageID], GT, index,
                        (isLastPage ? lastPageSize : PAGE_SIZE) - index);
                    if (index != -1)
                    {
                        object o = (loPageID, lo, pageID, index - 1, previous);
                        (previous = new Thread(Reverse)).Start(o);
                        break;
                    }
                    else if (isLastPage)
                    {
                        Reverse((loPageID, lo, pageID, lastPageSize - 1, previous));
                        canWriteCount = readCount;
                        return;
                    }
                    pageID++;
                    index = 0;
                }
            }
        }).Start();

        // Use a ManualResetEvent to know when processing is complete
        var processingComplete = new ManualResetEvent(false);

        new Thread(() =>
        {
            using var outStream = Console.OpenStandardOutput();
            int writtenCount = 0;
            while (true)
            {
                while (writtenCount == canWriteCount) Thread.Sleep(0);
                var page = pages[writtenCount++];
                if (writtenCount == readCount && lastPageSize != PAGE_SIZE)
                {
                    outStream.Write(page, 0, lastPageSize);
                    ArrayPool<byte>.Shared.Return(page);
                    processingComplete.Set(); // Signal completion
                    return;
                }
                outStream.Write(page, 0, PAGE_SIZE);
                ArrayPool<byte>.Shared.Return(page);
            }
        }).Start();

        // Wait for processing to complete
        processingComplete.WaitOne();
    }
}
