using System;
using System.Runtime.InteropServices;
using System.Numerics;

// inspired from https://stackoverflow.com/questions/24374658/check-the-operating-system-at-compile-time 
#if _LINUX
    const string pathToLib = @"target/release/librapl_lib.so";
#elif _WINDOWS
    const string pathToLib = @"target\release\rapl_lib.dll";
#else
    const string pathToLib = "none";
#endif

string[] arguments = Environment.GetCommandLineArgs();
uint count = uint.Parse(arguments[1]);
uint fibVal = uint.Parse(arguments[2]);

// DLL imports
[DllImport(pathToLib)]
static extern int start_rapl();

[DllImport(pathToLib)]
static extern void stop_rapl();

// test method from Rosetta code
static ulong Fib(uint n) {
    return (n < 2)? n : Fib(n - 1) + Fib(n - 2);
}

// running benchmark
for (int i = 0; i < count; i++)
{
    start_rapl();

    var result = Fib(fibVal);

    stop_rapl();
    if (result < 42){
        Console.WriteLine(result.ToString());
    }
}
