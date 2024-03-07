using CsharpRAPL.Benchmarking.Attributes;
using CsharpRAPL.Benchmarking.Attributes.Parameters;
using CsharpRAPL.Benchmarking.Lifecycles;
using SocketComm;

namespace EnergyTest;

public class JavaBenchmarks {
    /* The Computer Language Benchmark Game */
    // ------------------------------------
    [Benchmark("Java", "Fannkuch-Redux Java", typeof(IpcBenchmarkLifecycle),
    name: "FannkuchRedux", skip: true, loopIterations: 1)]
    public static JavaState FannkuchRedux(IpcState s) {
        return new JavaState(s) {
            RootPath = "Java",
            BenchmarkPath = "FannkuchRedux",
            BenchmarkSignature = "FannkuchRedux.FannkuchRedux(12)",
            AdditionalCompilerOptions = "-server"
        };
    }

    [Benchmark("Java", "N-Body Java", typeof(IpcBenchmarkLifecycle),
    name: "NBody", skip: true, loopIterations: 1)]
    public static JavaState NBody(IpcState s) {
        return new JavaState(s) {
            RootPath = "Java",
            BenchmarkPath = "NBody",
            BenchmarkSignature = "NBody.NBody(50000000)",
            AdditionalCompilerOptions = "-server"
        };
    }

    [Benchmark("Java", "Spectral-Norm Java", typeof(IpcBenchmarkLifecycle),
    name: "SpectralNorm", skip: true, loopIterations: 1)]
    public static JavaState SpectralNorm(IpcState s) {
        return new JavaState(s) {
            RootPath = "Java",
            BenchmarkPath = "SpectralNorm",
            BenchmarkSignature = "SpectralNorm.SpectralNorm(7000)",
            AdditionalCompilerOptions = "-server"
        };
    }

    [Benchmark("Java", "Mandelbrot Java", typeof(IpcBenchmarkLifecycle),
    name: "Mandelbrot", skip: true, loopIterations: 1)]
    public static JavaState Mandelbrot(IpcState s) {
        return new JavaState(s) {
            RootPath = "Java",
            BenchmarkPath = "Mandelbrot",
            BenchmarkSignature = "Mandelbrot.Mandelbrot(16000)",
            AdditionalCompilerOptions = "-server"
        };
    }

    [Benchmark("Java", "Pidigits Java", typeof(IpcBenchmarkLifecycle),
    name: "Pidigits", skip: true, loopIterations: 1)]
    public static JavaState Pidigits(IpcState s) {
        return new JavaState(s) {
            RootPath = "Java",
            BenchmarkPath = "Pidigits",
            BenchmarkSignature = "Pidigits.Pidigits(10000)",
            AdditionalCompilerOptions = "-server"
        };
    }
    /* The Computer Language Benchmark Game */
    // ------------------------------------

    /* Peter Sestoft */
    // -------------
    [Benchmark("Java", "Division Intensive Loop Java", typeof(IpcBenchmarkLifecycle),
    name: "DivisionLoop", skip: false, loopIterations: 1)]
    public static JavaState DivisionLoop(IpcState s) {
        return new JavaState(s) {
            RootPath = "Java",
            BenchmarkPath = "DivisionLoop",
            BenchmarkSignature = "DivisionLoop.DivisionLoop(22)",
            AdditionalCompilerOptions = "-server"
        };
    }

    [Benchmark("Java", "Matrix Multiplication Java", typeof(IpcBenchmarkLifecycle),
    name: "MatrixMultiplication", skip: false, loopIterations: 1)]
    public static JavaState MatrixMultiplication(IpcState s) {
        return new JavaState(s) {
            RootPath = "Java",
            BenchmarkPath = "MatrixMultiplication",
            BenchmarkSignature = "MatrixMultiplication.MatrixMultiplication(80, 80)",
            AdditionalCompilerOptions = "-server"
        };
    }

    [Benchmark("Java", "Polynomial Evaluation Java", typeof(IpcBenchmarkLifecycle),
    name: "PolynomialEvaluation", skip: false, loopIterations: 1)]
    public static JavaState PolynomialEvaluation(IpcState s) {
        return new JavaState(s) {
            RootPath = "Java",
            BenchmarkPath = "PolynomialEvaluation",
            BenchmarkSignature = "PolynomialEvaluation.PolynomialEvaluation(10000)",
            AdditionalCompilerOptions = "-server"
        };
    }
    /* Peter Sestoft */
    // -------------
}
