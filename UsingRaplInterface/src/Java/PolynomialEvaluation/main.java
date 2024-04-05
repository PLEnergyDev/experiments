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

            PolynomialEvaluation.Run(n);

            try {
                stop_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }
        }
    }

////////////////////////////////////////////////////////////////////////////////////////
	public class PolynomialEvaluation {
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
		    System.out.println(res);
		    return res;
		}
	}
////////////////////////////////////////////////////////////////////////////////////////
}