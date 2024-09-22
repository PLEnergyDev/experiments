namespace CsharpIPC;

public class MatrixMultiplication {
	static double[,] InitMatrix(int rows, int cols) {
		double[,] m = new double[rows, cols];
		for (int i = 0; i < rows; i++) {
			for (int j = 0; j < cols; j++) {
				m[i, j] = i + j;
			}
		}
		return m;
	}

	public static double RunMatrixMultiplication(int rows, int cols) {
		double[,] R = new double[rows, cols];
		double[,] A = InitMatrix(rows, cols);
		double[,] B = InitMatrix(rows, cols);

		// Maintaining consistency with "Numeric performance in C, C# and Java"
		// by Peter Sestoft
		int aCols = A.GetLength(1);
		int rRows = R.GetLength(0);
		int rCols = R.GetLength(1);

		double sum = 0.0;
	    for (int r = 0; r < rRows; r++) {
	        for (int c = 0; c < rCols; c++) {
	            sum = 0.0;
	            for (int k = 0; k < aCols; k++) {
	                sum += A[r, k] * B[k, c];
	            }
	            R[r, c] = sum;
	        }
	    }
	    return sum;
	}

	public static double RunMatrixMultiplicationUnsafe(int rows, int cols) {
		double[,] R = new double[rows, cols];
		double[,] A = InitMatrix(rows, cols);
		double[,] B = InitMatrix(rows, cols);

		// Maintaining consistency with "Numeric performance in C, C# and Java"
		// by Peter Sestoft
		int aCols = A.GetLength(1);
		int bCols = B.GetLength(1);
		int rRows = R.GetLength(0);
		int rCols = R.GetLength(1);

		double sum = 0.0;
	    for (int r = 0; r < rRows; r++) {
	        for (int c = 0; c < rCols; c++) {
	            sum = 0.0;
	            unsafe {
	            	fixed (double* abase = &A[r, 0], bbase = &B[0, c]) {
			            for (int k = 0; k < aCols; k++) {
			                sum += abase[k] * bbase[k*bCols];
			            }
	            	}
	            }
	            R[r, c] = sum;
	        }
	    }
	    return sum;
	}
}