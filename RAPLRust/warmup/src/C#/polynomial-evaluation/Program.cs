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
        int n = int.Parse(arguments[2]);

        for (int i = 0; i < iterations; i++)
        {
            start_rapl();
            for (int j = 0; j < 1000; j++)
            {
                run_benchmark(n);
            }
            stop_rapl();
        }
    }

    static void run_benchmark(int n)
    {
        double sum = PolynomialEvaluation.Run(n);
        Console.WriteLine(sum);
    }
}

public static class PolynomialEvaluation
{
    static double[] InitCS(int n)
    {
        double[] cs = new double[n];
        for (int i = 0; i < n; i++)
        {
            cs[i] = 1.1 * i;
            if (i % 3 == 0)
            {
                cs[i] *= -1;
            }
        }

        return cs;
    }

    public static double Run(int n)
    {
        double[] cs = InitCS(n);
        double res = 0.0;

        for (int i = 0; i < n; i++)
        {
            res = cs[i] + 5.0 * res;
        }

        return res;
    }
}
