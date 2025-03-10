import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;

public class program {
    static {
        System.loadLibrary("rapl_interface");
    }

    static void run_benchmark(int m) {
        double sum = 0.0;
        int n = 0;
        while (sum < m) {
            n++;
            sum += 1.0 / n;
        }
        System.out.printf("%d\n", n);
    }

    public static void main(String[] args) throws Throwable {
        SymbolLookup lookup = SymbolLookup.loaderLookup();

        MethodHandle start_rapl = Linker.nativeLinker().downcallHandle(
                lookup.find("start_rapl").get(),
                FunctionDescriptor.of(ValueLayout.JAVA_INT)
        );

        MethodHandle stop_rapl = Linker.nativeLinker().downcallHandle(
                lookup.find("stop_rapl").get(),
                FunctionDescriptor.ofVoid()
        );

        int m = Integer.parseInt(args[0]);

        while ((int) start_rapl.invokeExact() > 0) {
            run_benchmark(m);
            stop_rapl.invokeExact();
        }
    }
}
