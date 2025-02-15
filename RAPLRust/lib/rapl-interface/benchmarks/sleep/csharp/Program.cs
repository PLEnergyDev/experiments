using System;
using System.Runtime.InteropServices;

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
int sleepTime = int.Parse(arguments[2]);

[DllImport(pathToLib)]
static extern int start_rapl();

[DllImport(pathToLib)]
static extern void stop_rapl();

for (int i = 0; i < count; i++)
{
    start_rapl();
    System.Threading.Thread.Sleep(sleepTime*1000);
    stop_rapl();
}
