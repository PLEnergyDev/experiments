using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using System.Runtime.Intrinsics.X86;
using System.Runtime.Intrinsics;
using System;

const string pathToLib = "rapl-interface/target/release/librapl_lib.so";

// DLL imports
[DllImport(pathToLib)]
static extern int start_rapl();

[DllImport(pathToLib)]
static extern void stop_rapl();

string[] arguments = Environment.GetCommandLineArgs();
uint count = uint.Parse(arguments[1]);
int rows = int.Parse(arguments[2]);
int cols = int.Parse(arguments[3]);

for (int i = 0; i < count; i++)
{
    start_rapl();
    MatrixMultiplicationUnsafe.Run(rows, cols);
    stop_rapl();
}

////////////////////////////////////////////////////////////////////////////////////////
public static class MatrixMultiplicationUnsafe {
    static double[,] InitMatrix(int rows, int cols) {
        double[,] m = new double[rows, cols];
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                m[i, j] = i + j;
            }
        }
        return m;
    }

    public static double Run(int rows, int cols) {
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
////////////////////////////////////////////////////////////////////////////////////////
