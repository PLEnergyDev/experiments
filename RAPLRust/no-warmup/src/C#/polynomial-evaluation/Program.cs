using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using System;

string[] arguments = Environment.GetCommandLineArgs();
int n = int.Parse(arguments[1]);
for (int i = 0; i < 1000; i++) {
    double sum = PolynomialEvaluation.Run(n);
    Console.WriteLine(sum);
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
