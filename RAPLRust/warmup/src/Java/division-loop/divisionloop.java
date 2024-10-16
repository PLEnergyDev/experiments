import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;

public class divisionloop {
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

        // Running benchmark
        for (int counter = 0; counter < count; counter++) {
            try {
                start_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }

            int M = Integer.parseInt(args[1]);
            for (int i = 0; i < 10; i++) {
                double result = divisionLoop(M);
                System.out.printf("%f%n", result);
            }

            try {
                stop_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }
        }
    }
}