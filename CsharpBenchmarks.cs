using CsharpRAPL.Benchmarking.Attributes;
using CsharpRAPL.Benchmarking.Attributes.Parameters;
using CsharpRAPL.Benchmarking.Lifecycles;
using SocketComm;

namespace EnergyTest;

public class CsharpBenchmarks {
    /* The Computer Language Benchmark Game */
    // ------------------------------------
    [Benchmark("C#", "Fannkuch-Redux C#", typeof(IpcBenchmarkLifecycle),
    name: "FannkuchRedux", skip: true, loopIterations: 1)]
    public static CsharpState FannkuchRedux(IpcState s) {
        return new CsharpState (s) {
            RootPath = "C#",
            BenchmarkPath = "FannkuchRedux",
            BenchmarkSignature = "FannkuchRedux.RunFannkuchRedux(12)",
            AdditionalCompilerOptions = "-c Release --no-restore --no-self-contained"
        };
    }

    [Benchmark("C#", "N-Body C#", typeof(IpcBenchmarkLifecycle),
    name: "NBody", skip: true, loopIterations: 1)]
    public static CsharpState NBody(IpcState s) {
        return new CsharpState (s) {
            RootPath = "C#",
            BenchmarkPath = "NBody",
            BenchmarkSignature = "NBody.RunNBody(50000000)",
            AdditionalCompilerOptions = "-c Release --no-restore --no-self-contained"
        };
    }

    [Benchmark("C#", "Spectral-Norm C#", typeof(IpcBenchmarkLifecycle),
    name: "SpectralNorm", skip: true, loopIterations: 1)]
    public static CsharpState SpectralNorm(IpcState s) {
        return new CsharpState (s) {
            RootPath = "C#",
            BenchmarkPath = "SpectralNorm",
            BenchmarkSignature = "SpectralNorm.RunSpectralNorm(7000)",
            AdditionalCompilerOptions = "-c Release --no-restore --no-self-contained"
        };
    }

    [Benchmark("C#", "Mandelbrot C#", typeof(IpcBenchmarkLifecycle),
    name: "Mandelbrot", skip: true, loopIterations: 1)]
    public static CsharpState Mandelbrot(IpcState s) {
        return new CsharpState (s) {
            RootPath = "C#",
            BenchmarkPath = "Mandelbrot",
            BenchmarkSignature = "Mandelbrot.RunMandelbrot(16000)",
            AdditionalCompilerOptions = "-c Release --no-restore --no-self-contained"
        };
    }

    [Benchmark("C#", "Pidigits C#", typeof(IpcBenchmarkLifecycle),
    name: "Pidigits", skip: true, loopIterations: 1)]
    public static CsharpState Pidigits(IpcState s) {
        return new CsharpState (s) {
            RootPath = "C#",
            BenchmarkPath = "Pidigits",
            BenchmarkSignature = "Pidigits.RunPidigits(10000)",
            AdditionalCompilerOptions = "-c Release --no-restore --no-self-contained"
        };
    }
    /* The Computer Language Benchmark Game */
    // ------------------------------------

    /* Peter Sestoft */
    // -------------
    [Benchmark("C#", "Division Intensive Loop C#", typeof(IpcBenchmarkLifecycle),
    name: "DivisionLoop", skip: false, loopIterations: 1)]
    public static CsharpState DivisionLoop(IpcState s) {
        return new CsharpState (s) {
            RootPath = "C#",
            BenchmarkPath = "DivisionLoop",
            BenchmarkSignature = "DivisionLoop.RunDivisionLoop(22)",
            AdditionalCompilerOptions = "-c Release --no-restore --no-self-contained"
        };
    }

    [Benchmark("C#", "Matrix Multiplication C#", typeof(IpcBenchmarkLifecycle),
    name: "MatrixMultiplication", skip: false, loopIterations: 1)]
    public static CsharpState MatrixMultiplication(IpcState s) {
        return new CsharpState (s) {
            RootPath = "C#",
            BenchmarkPath = "MatrixMultiplication",
            BenchmarkSignature = "MatrixMultiplication.RunMatrixMultiplication(80, 80)",
            AdditionalCompilerOptions = "-c Release --no-restore --no-self-contained"
        };
    }

    [Benchmark("C#", "Matrix Multiplication Unsafe C#", typeof(IpcBenchmarkLifecycle),
    name: "MatrixMultiplicationUnsafe", skip: false, loopIterations: 1)]
    public static CsharpState MatrixMultiplicationUnsafe(IpcState s) {
        return new CsharpState (s) {
            RootPath = "C#",
            BenchmarkPath = "MatrixMultiplication",
            BenchmarkSignature = "MatrixMultiplication.RunMatrixMultiplicationUnsafe(80, 80)",
            AdditionalCompilerOptions = "-c Release --no-restore --no-self-contained"
        };
    }

    [Benchmark("C#", "Poynomial Evaluation C#", typeof(IpcBenchmarkLifecycle),
    name: "PolynomialEvaluation", skip: false, loopIterations: 1)]
    public static CsharpState PolynomialEvaluation(IpcState s) {
        return new CsharpState (s) {
            RootPath = "C#",
            BenchmarkPath = "PolynomialEvaluation",
            BenchmarkSignature = "PolynomialEvaluation.RunPolynomialEvaluation(10000)",
            AdditionalCompilerOptions = "-c Release --no-restore --no-self-contained"
        };
    }
    /* Peter Sestoft */
    // -------------
}
