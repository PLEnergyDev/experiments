/* The Computer Language Benchmarks Game
   http://benchmarksgame.alioth.debian.org/

   started with Java #2 program (Krause/Whipkey/Bennet/AhnTran/Enotus/Stalcup)
   adapted for C# by Jan de Vaan
*/

using System;
using System.Threading;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

public class MandelBrot
{
    [DllImport("librapl_interface", EntryPoint = "start_rapl")]
    public static extern bool start_rapl();

    [DllImport("librapl_interface", EntryPoint = "stop_rapl")]
    public static extern void stop_rapl();

    private static int n = 200;
    private static byte[][] data;
    private static int lineCount;
    private static double[] Crb;
    private static double[] Cib;

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static int getByte(int x, int y)
    {
        int res = 0;
        for (int i = 0; i < 8; i += 2)
        {
            double Zr1 = Crb[x + i];
            double Zi1 = Cib[y];

            double Zr2 = Crb[x + i + 1];
            double Zi2 = Cib[y];

            int b = 0;
            int j = 49;
            do
            {
                double nZr1 = Zr1 * Zr1 - Zi1 * Zi1 + Crb[x + i];
                double nZi1 = Zr1 * Zi1 + Zr1 * Zi1 + Cib[y];
                Zr1 = nZr1; Zi1 = nZi1;

                double nZr2 = Zr2 * Zr2 - Zi2 * Zi2 + Crb[x + i + 1];
                double nZi2 = Zr2 * Zi2 + Zr2 * Zi2 + Cib[y];
                Zr2 = nZr2; Zi2 = nZi2;

                if (Zr1 * Zr1 + Zi1 * Zi1 > 4) { b |= 2; if (b == 3) break; }
                if (Zr2 * Zr2 + Zi2 * Zi2 > 4) { b |= 1; if (b == 3) break; }
            } while (--j > 0);
            res = (res << 2) + b;
        }
        return res ^ -1;
    }

    public static void Main(String[] args)
    {
        int iterations = int.Parse(args[0]);
        if (args.Length > 0) n = Int32.Parse(args[1]);

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
        lineCount = -1;
        int lineLen = (n - 1) / 8 + 1;
        data = new byte[n][];
        Crb = new double[n + 7];
        Cib = new double[n + 7];

        double invN = 2.0 / n;
        for (int i = 0; i < n; i++)
        {
            Cib[i] = i * invN - 1.0;
            Crb[i] = i * invN - 1.5;
        }
    }

    static void run_benchmark()
    {
        var threads = new Thread[Environment.ProcessorCount];
        int lineLen = (n - 1) / 8 + 1;

        for (int i = 0; i < threads.Length; i++)
        {
            threads[i] = new Thread(() =>
            {
                int y;
                while ((y = Interlocked.Increment(ref lineCount)) < n)
                {
                    var buffer = new byte[lineLen];
                    for (int x = 0; x < lineLen; x++)
                    {
                        buffer[x] = (byte)getByte(x * 8, y);
                    }
                    data[y] = buffer;
                }
            });
            threads[i].Start();
        }

        foreach (var t in threads) t.Join();

        Console.Out.WriteLine("P4\n{0} {0}", n);
        var s = Console.OpenStandardOutput();
        for (int y = 0; y < n; y++) s.Write(data[y], 0, data[y].Length);
    }

    static void cleanup()
    {
        data = null;
        Crb = null;
        Cib = null;
    }
}
