import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;

class polynomialevaluation {
    public static void main(String[] args) {
        // Finding the path of library (and loading it)
        var dll_path = System.getProperty("user.dir") + "/../../rapl-interface/target/release/librapl_lib.so";
        System.load(dll_path);

        // Loading functions
        MemorySegment start_rapl_symbol = SymbolLookup.loaderLookup().find("start_rapl").get();
        MethodHandle start_rapl = Linker.nativeLinker().downcallHandle(start_rapl_symbol,
            FunctionDescriptor.of(ValueLayout.JAVA_INT));

        MemorySegment stop_rapl_symbol = SymbolLookup.loaderLookup().find("stop_rapl").get();
        MethodHandle stop_rapl = Linker.nativeLinker().downcallHandle(stop_rapl_symbol,
            FunctionDescriptor.of(ValueLayout.JAVA_INT));


        int count = Integer.parseInt(args[0]);
        int n = Integer.parseInt(args[1]);
        for (int counter = 0; counter < count; counter++) {
            try {
                start_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }


            for (int i = 0; i < 1000; i++) {
                double sum = Bench.Run(n);
                System.out.println(sum);
            }

            try {
                stop_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }
        }
    }

    public class Bench {
        static double[] InitCS(int n) {
            double[] cs = new double[n];
            for (int i = 0; i < n; i++) {
                cs[i] = 1.1 * i;
                if (i % 3 == 0) {
                    cs[i] *= -1;
                }
            }

            return cs;
        }

        public static double Run(int n) {
            double[] cs = InitCS(n);
            double res = 0.0;

            for (int i = 0; i < n; i++) {
                res = cs[i] + 5.0 * res;
            }
            return res;
        }
    }
}