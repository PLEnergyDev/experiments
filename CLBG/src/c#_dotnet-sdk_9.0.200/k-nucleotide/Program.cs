/* The Computer Language Benchmarks Game
   https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
 *
 * submitted by Josh Goldfoot
 * 
 */

using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;

public class Program
{
    [DllImport("librapl_interface", EntryPoint = "start_rapl")]
    private static extern bool start_rapl();

    [DllImport("librapl_interface", EntryPoint = "stop_rapl")]
    private static extern void stop_rapl();

    public static void Main(string[] args)
    {
        byte[] inputData;
        using (var ms = new MemoryStream())
        {
            Console.OpenStandardInput().CopyTo(ms);
            inputData = ms.ToArray();
        }

        while (true)
        {
            var inputStream = initialize(inputData);
            if (!start_rapl()) break;
            run_benchmark(inputStream);
            stop_rapl();
            cleanup(inputStream);
        }
    }

    private static MemoryStream initialize(byte[] inputData)
    {
        return new MemoryStream(inputData);
    }

    private static void cleanup(MemoryStream inputStream)
    {
        inputStream.Dispose();
    }

    private static void run_benchmark(MemoryStream inputStream)
    {
        PrepareLookups();
        var buffer = GetBytesForThirdSequence(inputStream);
        var fragmentLengths = new[] { 1, 2, 3, 4, 6, 12, 18 };
        var dicts =
            (from fragmentLength in fragmentLengths.AsParallel()
             select CountFrequency(buffer, fragmentLength)).ToArray();
        int buflen = dicts[0].Values.Sum(x => x.V);
        WriteFrequencies(dicts[0], buflen, 1);
        WriteFrequencies(dicts[1], buflen, 2);
        WriteCount(dicts[2], "GGT");
        WriteCount(dicts[3], "GGTA");
        WriteCount(dicts[4], "GGTATT");
        WriteCount(dicts[5], "GGTATTTTAATT");
        WriteCount(dicts[6], "GGTATTTTAATTTATAGT");
    }

    private static void WriteFrequencies(Dictionary<ulong, Wrapper> freq, int buflen, int fragmentLength)
    {

        double percent = 100.0 / (buflen - fragmentLength + 1);
        foreach (var line in (from k in freq.Keys
                              orderby freq[k].V descending
                              select string.Format("{0} {1:f3}", PrintKey(k, fragmentLength),
                                (freq.ContainsKey(k) ? freq[k].V : 0) * percent)))
            Console.WriteLine(line);
        Console.WriteLine();
    }

    private static void WriteCount(Dictionary<ulong, Wrapper> dictionary, string fragment)
    {
        ulong key = 0;
        var keybytes = Encoding.ASCII.GetBytes(fragment.ToLower());
        for (int i = 0; i < keybytes.Length; i++)
        {
            key <<= 2;
            key |= tonum[keybytes[i]];
        }
        Wrapper w;
        Console.WriteLine("{0}\t{1}", 
            dictionary.TryGetValue(key, out w) ? w.V : 0, 
            fragment);
    }

    private static string PrintKey(ulong key, int fragmentLength)
    {
        char[] items = new char[fragmentLength];
        for (int i = 0; i < fragmentLength; ++i)
        {
            items[fragmentLength - i - 1] = tochar[key & 0x3];
            key >>= 2;
        }
        return new string(items);
    }

    private static Dictionary<ulong, Wrapper> CountFrequency(byte[] buffer, int fragmentLength)
    {
        var dictionary = new Dictionary<ulong, Wrapper>();
        ulong rollingKey = 0;
        ulong mask = 0;
        int cursor;
        for (cursor = 0; cursor < fragmentLength - 1; cursor++)
        {
            rollingKey <<= 2;
            rollingKey |= tonum[buffer[cursor]];
            mask = (mask << 2) + 3;
        }
        mask = (mask << 2) + 3;
        int stop = buffer.Length;
        Wrapper w;
        byte cursorByte;
        while (cursor < stop)
        {
            if ((cursorByte = buffer[cursor++]) < (byte)'a')
                cursorByte = buffer[cursor++];
            rollingKey = ((rollingKey << 2) & mask) | tonum[cursorByte];
            if (dictionary.TryGetValue(rollingKey, out w))
                w.V++;
            else
                dictionary.Add(rollingKey, new Wrapper(1));
        }
        return dictionary;
    }

    private static byte[] GetBytesForThirdSequence(MemoryStream inputStream)
    {
        const int buffersize = 2500120;
        byte[] threebuffer = null;
        var buffer = new byte[buffersize];
        int amountRead, threebuflen, indexOfFirstByteInThreeSequence, indexOfGreaterThan, threepos, tocopy;
        amountRead = threebuflen = indexOfFirstByteInThreeSequence = indexOfGreaterThan = threepos = tocopy = 0;
        bool threeFound = false;
        
        // Use the provided memory stream
        var source = new BufferedStream(inputStream);
        
        while (!threeFound && (amountRead = source.Read(buffer, 0, buffersize)) > 0)
        {
            indexOfGreaterThan = Array.LastIndexOf(buffer, (byte)'>');
            threeFound = (indexOfGreaterThan > -1 &&
                buffer[indexOfGreaterThan + 1] == (byte)'T' &&
                buffer[indexOfGreaterThan + 2] == (byte)'H');
            if (threeFound)
            {
                threepos += indexOfGreaterThan;
                threebuflen = threepos - 48;
                threebuffer = new byte[threebuflen];
                indexOfFirstByteInThreeSequence = Array.IndexOf<byte>(buffer, 10, indexOfGreaterThan) + 1;
                tocopy = amountRead - indexOfFirstByteInThreeSequence;
                if (amountRead < buffersize)
                    tocopy -= 1;
                Buffer.BlockCopy(buffer, indexOfFirstByteInThreeSequence, threebuffer, 0, tocopy);
                buffer = null;
            }
            else
                threepos += amountRead;
        }
        int toread = threebuflen - tocopy;
        source.Read(threebuffer, tocopy, toread);
        
        return threebuffer;
    }
    
    private static byte[] tonum = new byte[256];
    private static char[] tochar = new char[4];
    private static void PrepareLookups()
    {
        tonum['a'] = 0;
        tonum['c'] = 1;
        tonum['g'] = 2;
        tonum['t'] = 3;
        tochar[0] = 'A';
        tochar[1] = 'C';
        tochar[2] = 'G';
        tochar[3] = 'T';
    }
}

public class Wrapper
{
    public int V;
    public Wrapper(int v) { V = v; }
}
