using System.Diagnostics;
using CsharpRAPL.Benchmarking;
using CsharpRAPL.CommandLine;

var options = CsharpRAPLCLI.Parse(args);

var suite = new BenchmarkCollector();

suite.RunAll(options.Warmup);
