package JavaIPC;

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

	public static double MatrixMultiplication(int rows, int cols) {
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
		return sum;
	}
}