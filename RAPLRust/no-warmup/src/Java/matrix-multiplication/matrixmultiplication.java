public class matrixmultiplication {
    
    static class Matrix {
        int rows, cols;
        double[] data;

        // Constructor to initialize the matrix and allocate memory for data
        Matrix(int rows, int cols) {
            this.rows = rows;
            this.cols = cols;
            this.data = new double[rows * cols];
        }

        // Method to get the element at (row, col)
        double get(int row, int col) {
            return data[row * cols + col];
        }

        // Method to set the element at (row, col)
        void set(int row, int col, double value) {
            data[row * cols + col] = value;
        }
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
        if (args.length < 2) {
            System.out.println("Usage: java matrixmultiplication <rows> <cols>");
            return;
        }

        int rows = Integer.parseInt(args[0]);
        int cols = Integer.parseInt(args[1]);
        for (int i = 0; i < 100; i++) {
            double result = matrixMultiplication(rows, cols);
            System.out.printf("%f%n", result);
        }
    }
}
