import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;

public class matrixmultiplication {

    static class Matrix {
        int rows, cols;
        double[] data;

        Matrix(int rows, int cols) {
            this.rows = rows;
            this.cols = cols;
            this.data = new double[rows * cols];
        }

        double get(int row, int col) {
            return data[row * cols + col];
        }

        void set(int row, int col, double value) {
            data[row * cols + col] = value;
        }
    }

    static int rows;
    static int cols;
    static double result;

    public static void initialize(String[] args) {
        rows = Integer.parseInt(args[1]);
        cols = Integer.parseInt(args[2]);
    }

    public static void run_benchmark() {
        result = matrixMultiplication(rows, cols);
    }

    public static void cleanup() {
        // No cleanup necessary
    }

    public static Matrix initMatrix(int rows, int cols) {
        Matrix m = new Matrix(rows, cols);
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                m.set(i, j, i + j);
            }
        }
        return m;
    }

    public static double matrixMultiplication(int rows, int cols) {
        Matrix R = new Matrix(rows, cols);
        Matrix A = initMatrix(rows, cols);
        Matrix B = initMatrix(rows, cols);

        double sum = 0.0;
        for (int r = 0; r < R.rows; r++) {
            for (int c = 0; c < R.cols; c++) {
                sum = 0.0;
                for (int k = 0; k < A.cols; k++) {
                    sum += A.get(r, k) * B.get(k, c);
                }
                R.set(r, c, sum);
            }
        }

        return sum;
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
            for (int j = 0; j < 100; j++) {
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
