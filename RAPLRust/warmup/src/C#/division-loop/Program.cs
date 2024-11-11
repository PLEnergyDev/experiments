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
        int M = int.Parse(arguments[2]);

        for (int i = 0; i < iterations; i++)
        {
            initialize();
            start_rapl();
            for (int j = 0; j < 10; j++) {
                run_benchmark(M);
            }
            stop_rapl();
            cleanup();
        }
    }

    static void initialize()
    {
    }

    static void run_benchmark(int M)
    {
        int result = DivisionLoop.Run(M);
        Console.WriteLine(result);
    }

    static void cleanup()
    {
    }
}

public static class DivisionLoop
{
    public static int Run(int M)
    {
        double sum = 0.0;
        int n = 0;
        while (sum < M)
        {
            n++;
            sum += 1.0 / n;
        }
        return n;
    }
}
