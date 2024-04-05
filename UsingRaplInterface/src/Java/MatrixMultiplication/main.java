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
        int rows = Integer.parseInt(args[1]);
        int cols = Integer.parseInt(args[2]);

        // Running benchmark
        for (int i = 0; i < loop_count; i++) {
            try {
                start_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }

            MatrixMultiplication.Run(rows, cols);

            try {
                stop_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }
        }
    }

////////////////////////////////////////////////////////////////////////////////////////
    public class MatrixMultiplication {
        static double[][] InitMatrix(int rows, int cols) {
            double[][] m = new double[rows][cols];
            for (int i = 0; i < rows; i++) {
                for (int j = 0; j < cols; j++) {
                    m[i][j] = i + j;
                }
            }
            return m;
        }

        public static double Run(int rows, int cols) {
            double[][] R = new double[rows][cols];
            double[][] A = InitMatrix(rows, cols);
            double[][] B = InitMatrix(rows, cols);

            int aCols = A[0].length;
            int rRows = R.length;
            int rCols = R[0].length;

            double sum = 0.0;
            for (int r = 0; r < rRows; r++) {
                double[] Ar = A[r], Rr = R[r];
                for (int c = 0; c < rCols; c++) {
                    sum = 0.0;
                    for (int k = 0; k < aCols; k++) {
                        sum += Ar[k] * B[k][c];
                    }
                    Rr[c] = sum;
                }
            }
            System.out.println(sum);
            return sum;
        }
    }
}
////////////////////////////////////////////////////////////////////////////////////////
