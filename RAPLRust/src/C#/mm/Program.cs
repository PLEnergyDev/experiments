using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class Program {
    const string pathToLib = "../../../lib/rapl-interface/target/release/librapl_lib.so";

    [DllImport(pathToLib)]
    static extern int start_rapl();

    [DllImport(pathToLib)]
    static extern void stop_rapl();

    static void run_benchmark(int rows, int cols) {
        double[] A = new double[rows * cols];
        double[] B = new double[rows * cols];
        double[] R = new double[rows * cols];

        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                A[r * cols + c] = B[r * cols + c] = r + c;
            }
        }

        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                double sum = 0.0;
                for (int k = 0; k < cols; k++) {
                    sum += A[r * cols + k] * B[k * cols + c];
                }
                R[r * cols + c] = sum;
            }
        }

        double finalSum = R[(rows - 1) * cols + (cols - 1)];
        Console.WriteLine(finalSum);
    }

    static void Main(string[] args) {
        int iterations = int.Parse(args[0]);
        int rows = int.Parse(args[1]);
        int cols = int.Parse(args[2]);

        for (int i = 0; i < iterations; i++) {
            start_rapl();
            run_benchmark(rows, cols);
            stop_rapl();
        }
    }
}
