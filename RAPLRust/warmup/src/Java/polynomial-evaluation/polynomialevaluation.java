import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;

public class polynomialevaluation {

    static int n;
    static double result;

    public static void initialize(String[] args) {
        n = Integer.parseInt(args[1]);
    }

    public static void run_benchmark() {
        result = polynomialEvaluation(n);
    }

    public static void cleanup() {
        // No cleanup necessary
    }

    public static double[] initCs(int n) {
        double[] cs = new double[n];
        for (int i = 0; i < n; i++) {
            cs[i] = 1.1 * i;
            if (i % 3 == 0) {
                cs[i] *= -1;
            }
        }
        return cs;
    }

    public static double polynomialEvaluation(int n) {
        double[] cs = initCs(n);
        double res = 0.0;

        for (int i = 0; i < n; i++) {
            res = cs[i] + 5.0 * res;
        }

        return res;
    }

    public static void main(String[] args) {
        var dll_path = System.getProperty("user.dir") + "/../../rapl-interface/target/release/librapl_lib.so";
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
            for (int j = 0; j < 20000; j++) {
                run_benchmark();
                System.out.printf("%f%n", result);
            }
            try {
                stop_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }
            cleanup();
        }
    }
}
