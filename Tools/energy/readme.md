# Energy Measurement Toolkit

## Overview

The `energy` toolkit provides a simple interface for measuring the energy consumption of programs across different **languages** and **benchmarks**.

## Features

- Energy and performance measurements
- Standard interface for defining benchmarks
- Automated benchmark runner
- Automated benchmark result correctness verifier via MD5 hash
- Several reporting tools
- `Lab` setup for reproducible results
- `Production` setup for a performance environment with a background workload
- `Lightweight` setup for a performance environment with minimal background processes

## Prerequisites

Ensure the following dependencies are installed:
- `bash`
- `perf`
- `cpupower`
- `modprobe`
- `kmod`
- `linux-tools`

## Installation

Install with root privileges in the project root:

```bash
make install
```

## Usage

### Command Structure

```bash
energy [--version|--help] COMMAND [OPTIONS]
```

### Available Commands

| Command | Description |
|---------|-------------|
| `measure` | Use "perf" and "rapl_interface" to measure programs |
| `report` | Compiles measurement results into nice reports |
| `assembly` | Prints the assembly for a file and an overview of it to compare languages |

Execute a command with the `--help` flag to see more options:

```bash
energy measure --help
```

### Directory Structure

> [!NOTE]
> Every benchmark requires:
> - A `Makefile` file with a `measure` target
> - A `expected.txt` file containing the expected `stdout` output of the benchmark

Supports two measurement modes:
1. Can measure *while inside* single benchmark

```
benchmark/
├── [Source files]
├── Makefile
└── expected.txt
```

2. Multi-language benchmark suite where the following directory structure is required:

```
benchmark_set/
├── <language_1>/
│   ├── <benchmark_1>/
│   │   ├── [Source files]
│   │   ├── Makefile
│   │   └── expected.txt
│   └── ...
├── <language_2>/
│   ├── <benchmark_2>/
│   │   ├── [Source files]
│   │   ├── Makefile
│   │   └── expected.txt
│   └── ...
└── ...
```

## Language Integration

### Rapl Interface Library Usage

The toolkit uses the `rapl_interface` library to measure energy consumption.

#### C/C++
```c
#include <rapl-interface.h>

while (start_rapl()) {
    // Measurement code
    stop_rapl();
}
```

#### C#
```csharp
[DllImport("librapl_interface", EntryPoint = "start_rapl")]
public static extern bool start_rapl();
[DllImport("librapl_interface", EntryPoint = "stop_rapl")]
public static extern void stop_rapl();

while (start_rapl()) {
    // Measurement code
    stop_rapl();
}
```

#### Java
```java
static {
    System.loadLibrary("rapl_interface");
}
SymbolLookup lookup = SymbolLookup.loaderLookup();
MethodHandle start_rapl = Linker.nativeLinker().downcallHandle(
    lookup.find("start_rapl").get(),
    FunctionDescriptor.of(ValueLayout.JAVA_INT)
);
MethodHandle stop_rapl = Linker.nativeLinker().downcallHandle(
    lookup.find("stop_rapl").get(),
    FunctionDescriptor.ofVoid()
);

while (start_rapl() > 0) {
    // Measurement code
    stop_rapl();
}
```

#### Rust
```rust
#[link(name="rapl_interface")]
extern "C" {
    fn start_rapl() -> i32;
    fn stop_rapl();
}

while unsafe { start_rapl() } > 0 {
    // Measurement code
    unsafe { stop_rapl() };
}
```

## Measurement Metrics

Once a measurement is successful, the benchmark will receive:

1. If ran *inside* a single benchmark you will generate a `perf.txt` and an `Intel_x.csv` or `AMD_X.csv` depending on your CPU.

```
benchmark/
├── [Benchmark files]
├── Intel_x.csv -or- AMD_x.csv
└── perf.txt
```

2. If ran on a benchmark suite you will generate a `results` dir in the same location as your benchmark suite which will mirror the structure of the suite and contains `perf.txt` and `Intel_x.csv` or `AMD_X.csv` depending on your CPU.

```
results/
├── <language_1>/
│   ├── <benchmark_1>/
|   |   ├── Intel_x.csv -or- AMD_x.csv
|   |   └── perf.txt
│   └── ...
├── <language_2>/
│   ├── <benchmark_2>/
|   |   ├── Intel_x.csv -or- AMD_x.csv
|   |   └── perf.txt
│   └── ...
└── ...
benchmark_set/
├── <language_1>/
│   ├── <benchmark_1>/
│   │   └── [Benchmark files]
│   └── ...
├── <language_2>/
│   ├── <benchmark_2>/
│   │   └── [Benchmark files]
│   └── ...
└── ...
```

### Energy Metrics
- Package Domain (CPU die energy)
- DRAM energy
- Core (CPU cores) energy
- Uncore (integrated GPU, etc.) energy

### Performance Metrics
- Elapsed time
- Cache misses
- Branch misses
- LLC load misses
- CPU thermal margin
- CPU clock
- Cycles
- C-state residencies

## Report Generation

Using the aforementioned results, you can generate several reports with:

```bash
energy report
```

The report command follows the same usage pattern as `measure`, and can be used either within a single benchmark or on a suite.
