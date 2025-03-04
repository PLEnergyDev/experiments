# Energy Measurement Toolkit

## Overview

The `energy` toolkit provides a simple interface for measuring energy consumption of programs as well as a script which automates the process of measuring a set of programs (benchmarks).

## Features

## Prerequisites

Before using this script, ensure the following dependencies are installed:

- `bash`
- `perf`
- `cpupower`
- `modprobe`
- `kmod` package
- `linux-tools`

## Installation

`make install` with root priviledges in the root dir of `energy`.

## Usage

### Basic Command Structure

```bash
energy {--version|--help} COMMAND [ARGS]
```

### Commands

- `measure`: Measure program performance
- `report`: Compile raw measurements
- `export`: Export program assembly
- `help`: Display help for specific commands

### Using the `rapl_interface` library

`energy` uses the `rapl_interface` library which will be available on your host after installation. `energy` makes the assumption that you have a `Makefile` wich contains a target called `measure` in your project. You will want to execute your program as usual within the `measure` target. For example:

```make
measure: $(TARGET)
    ./$(TARGET)
```

#### C/C++ Programs

```C
// Compile with gcc/g++ -lrapl_interface -Wl,-rpath=/usr/local/lib
#include <rapl-interface.h>
// ...
while (start_rapl()) {
    // Code to measure multiple times
    stop_rapl();
}
```

#### C# Programs

```C#
using System.Runtime.InteropServices;

[DllImport("librapl_interface", EntryPoint = "start_rapl")]
public static extern bool start_rapl();

[DllImport("librapl_interface", EntryPoint = "stop_rapl")]
public static extern void stop_rapl();
// ...
while (start_rapl()) {
    // Code to measure multiple times
    stop_rapl();
}
```

#### Java Programs

```java
// Set this env var before running the program LD_LIBRARY_PATH=/usr/local/lib
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
// ...
while ((int) start_rapl.invokeExact() > 0) {
    // Code to measure multiple times
    stop_rapl.invokeExact();
}
```

#### Rust Programs

```rust
#[link(name="rapl_interface")]
extern "C" {
    fn start_rapl() -> i32;
    fn stop_rapl();
}
// ...
while unsafe { start_rapl() } > 0 {
    // Code to measure multiple times
    unsafe { stop_rapl() };
}
```

## Measurement Details

The script measures:

- Elapsed time
- `rapl` metrics:
    - Pkg Domain (Energy on CPU die)
    - Dram energy (Energy on DRAM attached to the CPU)
    - Core/PP0 energy (Energy of all CPU cores)
    - Uncore/PP1 energy (Energy of other components close to the CPU, e.g. integrated GPU)
- `perf` metrics:
    - Cache misses
    - Branch misses
    - LLC load misses
    - CPU thermal margin
    - CPU clock
    - Cycles
    - C-state residencies
