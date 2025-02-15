using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class Program {
    const string pathToLib = "../../rapl-interface/target/release/librapl_lib.so";

    // DLL imports
    [DllImport(pathToLib)]
    static extern int start_rapl();

    [DllImport(pathToLib)]
    static extern void stop_rapl();

    static void run_benchmark(int rows, int cols) {
        double[,] A = new double[rows, cols];
        double[,] B = new double[rows, cols];
        double[,] R = new double[rows, cols];

        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                A[r, c] = B[r, c] = r + c;
            }
        }

        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                double sum = 0.0;
                for (int k = 0; k < rows; k++) {
                    sum += A[r, k] * B[k, c];
                } 
                R[r, c] = sum;
            }
        }

        Console.WriteLine(R[rows - 1, cols - 1]);
    }

    static void Main(string[] args) {
        int iterations = int.Parse(args[0]);
        int rows = int.Parse(args[1]);
        int cols = int.Parse(args[2]);

        for (int i = 0; i < iterations; i++) {
            start_rapl();
            for (int j = 0; j < 1000; j++) {
                run_benchmark(rows, cols);
            }
            stop_rapl();
        }
    }
}
