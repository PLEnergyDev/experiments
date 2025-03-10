using System.Runtime.InteropServices;

public class Program {
    [DllImport("librapl_interface", EntryPoint = "start_rapl")]
    public static extern bool start_rapl();

    [DllImport("librapl_interface", EntryPoint = "stop_rapl")]
    public static extern void stop_rapl();

    static void run_benchmark(int m) {
        double sum = 0.0;
        int n = 0;
        while (sum < m) {
            n++;
            sum += 1.0 / n;
        }
        Console.WriteLine(n);
    }

    public static void Main(string[] args) {
        int m = int.Parse(args[0]);
        while (start_rapl()) {
            run_benchmark(m);
            stop_rapl();
        }
    }
}
