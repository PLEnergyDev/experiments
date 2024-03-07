using CsharpRAPL.Benchmarking.Attributes;
using CsharpRAPL.Benchmarking.Attributes.Parameters;
using CsharpRAPL.Benchmarking.Lifecycles;
using SocketComm;

namespace EnergyTest;

public class CBenchmarks {
    /* The Computer Language Benchmark Game */
    // ------------------------------------
    [Benchmark("C", "Fannkuch-Redux C gcc", typeof(IpcBenchmarkLifecycle),
    name: "FannkuchRedux", skip: true, loopIterations: 1)]
    public static CState FannkuchRedux(IpcState s) {
        return new CState(s) {
            RootPath = "src/C",
            BenchmarkPath = "FannkuchRedux",
            BenchmarkSignature = "FannkuchRedux(12)",
            AdditionalCompilerOptions = "-pipe -O3 -fomit-frame-pointer -march=ivybridge -pthread"
        };
    }

    [Benchmark("C", "N-Body C gcc", typeof(IpcBenchmarkLifecycle),
    name: "NBody", skip: true, loopIterations: 1)]
    public static CState NBody(IpcState s) {
        return new CState(s) {
            RootPath = "src/C",
            BenchmarkPath = "NBody",
            BenchmarkSignature = "NBody(50000000)",
            AdditionalCompilerOptions = "-pipe -O3 -fomit-frame-pointer -march=ivybridge -static -lm"
        };
    }

    [Benchmark("C", "Spectral-Norm C gcc", typeof(IpcBenchmarkLifecycle),
    name: "SpectralNorm", skip: true, loopIterations: 1)]
    public static CState SpectralNorm(IpcState s) {
        return new CState(s) {
            RootPath = "src/C",
            BenchmarkPath = "SpectralNorm",
            BenchmarkSignature = "SpectralNorm(7000)",
            AdditionalCompilerOptions = "-pipe -O3 -fomit-frame-pointer -march=ivybridge -fopenmp -lm"
        };
    }

    [Benchmark("C", "Mandelbrot C gcc", typeof(IpcBenchmarkLifecycle),
    name: "Mandelbrot", skip: true, loopIterations: 1)]
    public static CState Mandelbrot(IpcState s) {
        return new CState(s) {
            RootPath = "src/C",
            BenchmarkPath = "Mandelbrot",
            BenchmarkSignature = "Mandelbrot(16000)",
            AdditionalCompilerOptions = "-pipe -O3 -fomit-frame-pointer -march=ivybridge -mno-fma -fno-finite-math-only -fopenmp"
        };
    }

    [Benchmark("C", "Pidigits C gcc", typeof(IpcBenchmarkLifecycle),
    name: "Pidigits", skip: true, loopIterations: 1)]
    public static CState Pidigits(IpcState s) {
        return new CState(s) {
            RootPath = "src/C",
            BenchmarkPath = "Pidigits",
            BenchmarkSignature = "Pidigits(10000)",
            AdditionalCompilerOptions = "-pipe -O3 -fomit-frame-pointer -march=ivybridge -lgmp"
        };
    }
    /* The Computer Language Benchmark Game */
    // ------------------------------------

    /* Peter Sestoft */
    // -------------
    [Benchmark("C", "Division Intensive Loop C gcc", typeof(IpcBenchmarkLifecycle),
    name: "DivisionLoop", skip: false, loopIterations: 1)]
    public static CState DivisionLoop(IpcState s) {
        return new CState(s) {
            RootPath = "src/C",
            BenchmarkPath = "DivisionLoop",
            BenchmarkSignature = "DivisionLoop(22)",
            AdditionalCompilerOptions = "-O3"
        };
    }

    [Benchmark("C", "Matrix Multiplication C gcc", typeof(IpcBenchmarkLifecycle),
    name: "MatrixMultiplication", skip: false, loopIterations: 1)]
    public static CState MatrixMultiplication(IpcState s) {
        return new CState(s) {
            RootPath = "src/C",
            BenchmarkPath = "MatrixMultiplication",
            BenchmarkSignature = "MatrixMultiplication(80, 80)",
            AdditionalCompilerOptions = ""
        };
    }

    [Benchmark("C", "Polynomial Evaluation C gcc", typeof(IpcBenchmarkLifecycle),
    name: "PolynomialEvaluation", skip: false, loopIterations: 1)]
    public static CState PolynomialEvaluation(IpcState s) {
        return new CState(s) {
            RootPath = "src/C",
            BenchmarkPath = "PolynomialEvaluation",
            BenchmarkSignature = "PolynomialEvaluation(10000)",
            AdditionalCompilerOptions = ""
        };
    }
    /* Peter Sestoft */
    // -------------
}
