using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using System;

string[] arguments = Environment.GetCommandLineArgs();
int M = int.Parse(arguments[1]);
for (int i = 0; i < 10; i++) {
    double sum = DivisionLoop.Run(M);
    Console.WriteLine(sum);
}

public static class DivisionLoop {
    public static int Run(int M) {
        double sum = 0.0;
        int n = 0;
        while (sum < M) {
            n++;
            sum += 1.0 / n;
        }
        return n;
    }
}
