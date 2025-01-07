using System;
using System.Runtime.InteropServices;

public class Program
{
    const string pathToLib = "../../rapl-interface/target/release/librapl_lib.so";

    // DLL imports
    [DllImport(pathToLib)]
    static extern int start_rapl();

    [DllImport(pathToLib)]
    static extern void stop_rapl();

    public static void Main(string[] args)
    {
        string[] arguments = Environment.GetCommandLineArgs();
        int iterations = int.Parse(arguments[1]);
        int rows = int.Parse(arguments[2]);
        int cols = int.Parse(arguments[3]);

        for (int i = 0; i < iterations; i++)
        {
            initialize();
            start_rapl();
            for (int j = 0; j < 1000; j++) {
                run_benchmark(rows, cols);
            }
            stop_rapl();
            cleanup();
        }
    }

    static void initialize()
    {
    }

    static void run_benchmark(int rows, int cols)
    {
        double sum = MatrixMultiplication.Run(rows, cols);
        Console.WriteLine(sum);
    }

    static void cleanup()
    {
    }
}

public static class MatrixMultiplication
{
    static double[,] InitMatrix(int rows, int cols)
    {
        double[,] m = new double[rows, cols];
        for (int i = 0; i < rows; i++)
        {
            for (int j = 0; j < cols; j++)
            {
                m[i, j] = i + j;
            }
        }
        return m;
    }

    public static double Run(int rows, int cols)
    {
        double[,] R = new double[rows, cols];
        double[,] A = InitMatrix(rows, cols);
        double[,] B = InitMatrix(rows, cols);

        int aCols = A.GetLength(1);
        int rRows = R.GetLength(0);
        int rCols = R.GetLength(1);

        double sum = 0.0;
        for (int r = 0; r < rRows; r++)
        {
            for (int c = 0; c < rCols; c++)
            {
                sum = 0.0;
                for (int k = 0; k < aCols; k++)
                {
                    sum += A[r, k] * B[k, c];
                }
                R[r, c] = sum;
            }
        }
        return sum;
    }
}
