/* The Computer Language Benchmarks Game
   http://benchmarksgame.alioth.debian.org/

   contributed by Isaac Gouy
   modified by Josh Goldfoot, based on the Java version by The Anh Tran
*/

using System;
using System.Threading;
using System.Threading.Tasks;
using System.Runtime.InteropServices;

namespace SpectralNorms;

class Program {
    [DllImport("librapl_interface", EntryPoint = "start_rapl")]
    public static extern bool start_rapl();

    [DllImport("librapl_interface", EntryPoint = "stop_rapl")]
    public static extern void stop_rapl();

    public static void Main(String[] args)
    {
        int n = int.Parse(args[0]);
        while (true) {
            if (!start_rapl()) {
                break;
            }
            run_benchmark(n);
            stop_rapl();
        }
    }

    static void run_benchmark(int n)
    {
        Console.WriteLine("{0:f9}", spectralnormGame(n));
    }

    private static double spectralnormGame(int n)
    {
        double[] u = new double[n];
        double[] v = new double[n];
        double[] tmp = new double[n];

        for (int i = 0; i < n; i++)
            u[i] = 1.0;

        int nthread = Environment.ProcessorCount;
        int chunk = n / nthread;
        var barrier = new Barrier(nthread);
        Approximate[] ap = new Approximate[nthread];

        for (int i = 0; i < nthread; i++)
        {
            int r1 = i * chunk;
            int r2 = (i < (nthread - 1)) ? r1 + chunk : n;
            ap[i] = new Approximate(u, v, tmp, r1, r2, barrier);
        }

        double vBv = 0, vv = 0;
        for (int i = 0; i < nthread; i++)
        {
            ap[i].t.Wait();
            vBv += ap[i].m_vBv;
            vv += ap[i].m_vv;
        }

        return Math.Sqrt(vBv / vv);
    }
}

public class Approximate
{
    private Barrier barrier;
    public Task t;

    private double[] _u;
    private double[] _v;
    private double[] _tmp;

    private int range_begin, range_end;
    public double m_vBv, m_vv;

    public Approximate(double[] u, double[] v, double[] tmp, int rbegin, int rend, Barrier b)
    {
        m_vBv = 0;
        m_vv = 0;
        _u = u;
        _v = v;
        _tmp = tmp;
        range_begin = rbegin;
        range_end = rend;
        barrier = b;
        t = Task.Run(() => run());
    }

    private void run()
    {
        for (int i = 0; i < 10; i++)
        {
            MultiplyAtAv(_u, _tmp, _v);
            MultiplyAtAv(_v, _tmp, _u);
        }

        for (int i = range_begin; i < range_end; i++)
        {
            m_vBv += _u[i] * _v[i];
            m_vv += _v[i] * _v[i];
        }
    }

    private double eval_A(int i, int j)
    {
        return 1.0 / ((i + j) * (i + j + 1) / 2 + i + 1);
    }

    private void MultiplyAv(double[] v, double[] Av)
    {
        for (int i = range_begin; i < range_end; i++)
        {
            double sum = 0;
            for (int j = 0; j < v.Length; j++)
                sum += eval_A(i, j) * v[j];

            Av[i] = sum;
        }
    }

    private void MultiplyAtv(double[] v, double[] Atv)
    {
        for (int i = range_begin; i < range_end; i++)
        {
            double sum = 0;
            for (int j = 0; j < v.Length; j++)
                sum += eval_A(j, i) * v[j];

            Atv[i] = sum;
        }
    }

    private void MultiplyAtAv(double[] v, double[] tmp, double[] AtAv)
    {
        MultiplyAv(v, tmp);
        barrier.SignalAndWait();
        MultiplyAtv(tmp, AtAv);
        barrier.SignalAndWait();
    }
}
