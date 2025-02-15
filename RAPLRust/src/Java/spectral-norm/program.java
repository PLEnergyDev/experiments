/*
The Computer Language Benchmarks Game
https://salsa.debian.org/benchmarksgame-team/benchmarksgame/

Based on C# entry by Isaac Gouy
contributed by Jarkko Miettinen
Parallel by The Anh Tran
*/

import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.concurrent.CyclicBarrier;

public class program {
    private static final NumberFormat formatter = new DecimalFormat("#.000000000");
    static int n;
    static double result;

    public static void initialize(String[] args) {
        n = 1000;
        if (args.length > 0) n = Integer.parseInt(args[1]);
    }

    public static void run_benchmark() {
        result = spectralnormGame(n);
    }

    public static void cleanup() {
    }

    public static void main(String[] args) {
        var dll_path = System.getProperty("user.dir") + "/../../../lib/rapl-interface/target/release/librapl_lib.so";
        System.load(dll_path);

        // Loading functions
        MemorySegment start_rapl_symbol = SymbolLookup.loaderLookup().find("start_rapl").get();
        MethodHandle start_rapl = Linker.nativeLinker().downcallHandle(start_rapl_symbol,
                FunctionDescriptor.of(ValueLayout.JAVA_INT));

        MemorySegment stop_rapl_symbol = SymbolLookup.loaderLookup().find("stop_rapl").get();
        MethodHandle stop_rapl = Linker.nativeLinker().downcallHandle(stop_rapl_symbol,
                FunctionDescriptor.of(ValueLayout.JAVA_INT));

        int iterations = Integer.parseInt(args[0]);
        for (int i = 0; i < iterations; i++) {
            initialize(args);
            try {
                start_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }
            run_benchmark();
            System.out.println(formatter.format(result));
            try {
                stop_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }
            cleanup();
        }
    }

    private static final double spectralnormGame(int n) {
        double[] u = new double[n];
        double[] v = new double[n];
        double[] tmp = new double[n];

        for (int i = 0; i < n; i++)
            u[i] = 1.0;

        int nthread = Runtime.getRuntime().availableProcessors();
        Approximate.barrier = new CyclicBarrier(nthread);

        int chunk = n / nthread;
        Approximate[] ap = new Approximate[nthread];

        for (int i = 0; i < nthread; i++) {
            int r1 = i * chunk;
            int r2 = (i < (nthread - 1)) ? r1 + chunk : n;

            ap[i] = new Approximate(u, v, tmp, r1, r2);
        }

        double vBv = 0, vv = 0;
        for (int i = 0; i < nthread; i++) {
            try {
                ap[i].join();
                vBv += ap[i].m_vBv;
                vv += ap[i].m_vv;
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        return Math.sqrt(vBv / vv);
    }

    private static class Approximate extends Thread {
        private static CyclicBarrier barrier;
        private double[] _u;
        private double[] _v;
        private double[] _tmp;
        private int range_begin, range_end;
        private double m_vBv = 0, m_vv = 0;

        public Approximate(double[] u, double[] v, double[] tmp, int rbegin, int rend) {
            super();
            _u = u;
            _v = v;
            _tmp = tmp;
            range_begin = rbegin;
            range_end = rend;
            start();
        }

        public void run() {
            for (int i = 0; i < 10; i++) {
                MultiplyAtAv(_u, _tmp, _v);
                MultiplyAtAv(_v, _tmp, _u);
            }

            for (int i = range_begin; i < range_end; i++) {
                m_vBv += _u[i] * _v[i];
                m_vv += _v[i] * _v[i];
            }
        }

        private final static double eval_A(int i, int j) {
            int div = (((i + j) * (i + j + 1) >>> 1) + i + 1);
            return 1.0 / div;
        }

        private final void MultiplyAv(final double[] v, double[] Av) {
            for (int i = range_begin; i < range_end; i++) {
                double sum = 0;
                for (int j = 0; j < v.length; j++)
                    sum += eval_A(i, j) * v[j];
                Av[i] = sum;
            }
        }

        private final void MultiplyAtv(final double[] v, double[] Atv) {
            for (int i = range_begin; i < range_end; i++) {
                double sum = 0;
                for (int j = 0; j < v.length; j++)
                    sum += eval_A(j, i) * v[j];
                Atv[i] = sum;
            }
        }

        private final void MultiplyAtAv(final double[] v, double[] tmp, double[] AtAv) {
            try {
                MultiplyAv(v, tmp);
                barrier.await();
                MultiplyAtv(tmp, AtAv);
                barrier.await();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
