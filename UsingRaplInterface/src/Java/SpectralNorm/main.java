/*
The Computer Language Benchmarks Game
https://salsa.debian.org/benchmarksgame-team/benchmarksgame/

contributed by Ziad Hatahet
based on the Go entry by K P anonymous
*/

import java.text.DecimalFormat;
import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;

class Bench {
    public static void main(String[] args) {
        // Finding the path of library (and loading it)
        var dll_path = System.getProperty("user.dir") + "/rapl-interface/target/release/librapl_lib.so";
        System.load(dll_path);

        // Loading functions
        MemorySegment start_rapl_symbol = SymbolLookup.loaderLookup().find("start_rapl").get();
        MethodHandle start_rapl = Linker.nativeLinker().downcallHandle(start_rapl_symbol,
                FunctionDescriptor.of(ValueLayout.JAVA_INT));

        MemorySegment stop_rapl_symbol = SymbolLookup.loaderLookup().find("stop_rapl").get();
        MethodHandle stop_rapl = Linker.nativeLinker().downcallHandle(stop_rapl_symbol,
                FunctionDescriptor.of(ValueLayout.JAVA_INT));


        int loop_count = Integer.parseInt(args[0]);
        int n = Integer.parseInt(args[1]);

        // Running benchmark
        for (int i = 0; i < loop_count; i++) {
            try {
                start_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }

            try {
                spectralnorm.Run(n);
            } catch (Throwable e) {
                e.printStackTrace();
            }

            try {
                stop_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }
        }
    }
    public class spectralnorm {
        private static final DecimalFormat formatter = new DecimalFormat("#.000000000");
        private static final int NCPU = Runtime.getRuntime().availableProcessors();

        public static void Run(int n) throws InterruptedException {
            final var u = new double[n];
            for (int i = 0; i < n; i++)
                u[i] = 1.0;
            final var v = new double[n];
            for (int i = 0; i < 10; i++) {
                aTimesTransp(v, u);
                aTimesTransp(u, v);
            }

            double vBv = 0.0, vv = 0.0;
            for (int i = 0; i < n; i++) {
                final var vi = v[i];
                vBv += u[i] * vi;
                vv += vi * vi;
            }
            System.out.println(formatter.format(Math.sqrt(vBv / vv)));
        }

        private static void aTimesTransp(double[] v, double[] u) throws InterruptedException {
            final var x = new double[u.length];
            final var t = new Thread[NCPU];
            for (int i = 0; i < NCPU; i++) {
                t[i] = new Times(x, i * v.length / NCPU, (i + 1) * v.length / NCPU, u, false);
                t[i].start();
            }
            for (int i = 0; i < NCPU; i++)
                t[i].join();

            for (int i = 0; i < NCPU; i++) {
                t[i] = new Times(v, i * v.length / NCPU, (i + 1) * v.length / NCPU, x, true);
                t[i].start();
            }
            for (int i = 0; i < NCPU; i++)
                t[i].join();
        }

        private final static class Times extends Thread {
            private final double[] v, u;
            private final int ii, n;
            private final boolean transpose;

            public Times(double[] v, int ii, int n, double[] u, boolean transpose) {
                this.v = v;
                this.u = u;
                this.ii = ii;
                this.n = n;
                this.transpose = transpose;
            }

            @Override
            public void run() {
                final var ul = u.length;
                for (int i = ii; i < n; i++) {
                    double vi = 0.0;
                    for (int j = 0; j < ul; j++) {
                        if (transpose)
                            vi += u[j] / a(j, i);
                        else
                            vi += u[j] / a(i, j);
                    }
                    v[i] = vi;
                }
            }

            private static int a(int i, int j) {
                return (i + j) * (i + j + 1) / 2 + i + 1;
            }
        }
    }
}