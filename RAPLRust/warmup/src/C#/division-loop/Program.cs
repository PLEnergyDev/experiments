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
    int M = int.Parse(arguments[2]);
    double sum = DivisionLoop.Run(M);
    Console.WriteLine(sum);
    stop_rapl();
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
