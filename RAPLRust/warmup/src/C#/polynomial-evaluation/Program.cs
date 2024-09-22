using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using System.Runtime.Intrinsics.X86;
using System.Runtime.Intrinsics;
using System;

const string pathToLib = "../../rapl-interface/target/release/librapl_lib.so";

// DLL imports
[DllImport(pathToLib)]
static extern int start_rapl();

[DllImport(pathToLib)]
static extern void stop_rapl();

string[] arguments = Environment.GetCommandLineArgs();

uint count = uint.Parse(arguments[1]);
for (int i = 0; i < count; i++) {
    start_rapl();
    int n = int.Parse(arguments[2]);
    double sum = PolynomialEvaluation.Run(n);
    Console.WriteLine(sum);
    stop_rapl();
}

public static class PolynomialEvaluation {
    static double[] InitCS(int n) {
        double[] cs = new double[n];
        for (int i = 0; i < n; i++) {
            cs[i] = 1.1 * i;
            if (i % 3 == 0) {
                cs[i] *= -1;
            }
        }

        return cs;
    }

    public static double Run(int n) {
        double[] cs = InitCS(n);
        double res = 0.0;

        for (int i = 0; i < n; i++) {
            res = cs[i] + 5.0 * res;
        }

        return res;
    }
}
