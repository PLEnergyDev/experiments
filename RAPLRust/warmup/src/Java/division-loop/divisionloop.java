import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;

public class divisionloop {

    private static int M;
    private static double result;

    public static void initialize(String[] args) {
        M = Integer.parseInt(args[1]);
    }

    public static void run_benchmark() {
        result = divisionLoop(M);
    }

    public static void cleanup() {
        result = 0;
    }

    public static double divisionLoop(int M) {
        double sum = 0.0;
        int n = 0;
        while (sum < M) {
            n++;
            sum += 1.0 / n;
        }
        return n;
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
        for (int i = 0; i < iterations; ++i) {
            initialize(args);
            try {
                start_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }
            for (int j = 0; j < 10; j++) {
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
