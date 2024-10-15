using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using System.Runtime.Intrinsics.X86;
using System.Runtime.Intrinsics;
using System;


string[] arguments = Environment.GetCommandLineArgs();
int rows = int.Parse(arguments[1]);
int cols = int.Parse(arguments[2]);
for (int i = 0; i < 100; i++) {
    double sum = MatrixMultiplication.Run(rows, cols);
    Console.WriteLine(sum);
}

public static class MatrixMultiplication {
    static double[, ] InitMatrix(int rows, int cols) {
        double[, ] m = new double[rows, cols];
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                m[i, j] = i + j;
            }
        }
        return m;
    }

    public static double Run(int rows, int cols) {
        double[, ] R = new double[rows, cols];
        double[, ] A = InitMatrix(rows, cols);
        double[, ] B = InitMatrix(rows, cols);

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
}
