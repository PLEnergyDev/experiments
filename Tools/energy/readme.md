# Energy Measurement Toolkit

## Overview

The `energy` toolkit provides a simple interface for measuring energy consumption of programs across different languages and benchmarks.

## Features

- Comprehensive performance and energy measurement
- Support for multiple programming languages
- Automated benchmark testing
- Detailed metrics collection
- Flexible configuration options

## Prerequisites

Ensure the following dependencies are installed:
- `bash`
- `perf`
- `cpupower`
- `modprobe`
- `kmod`
- `linux-tools`
- `nix`

## Installation

Install with root privileges in the project root:
```bash
make install
```

## Usage

### Command Structure

```bash
energy {--version|--help} COMMAND [ARGS]
```

### Available Commands

| Command | Description |
|---------|-------------|
| `measure` | Measure program performance |
| `report` | Compile raw measurements |
| `assembly` | See program assembly |
| `help` | Display help for specific commands |

### Directory Structure

Supports two measurement modes:
1. Single project with a `Makefile`
2. Multi-language benchmark suite:

```
benchmark_set/
├── <language_1>/
│   ├── <benchmark_1>/
│   │   ├── [Source files]  
│   │   └── Makefile
│   └── ...
├── <language_2>/
│   ├── <benchmark_2>/
│   │   ├── [Source files]  
│   │   └── Makefile
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
[DllImport("librapl_interface")]
public static extern bool start_rapl();
[DllImport("librapl_interface")]
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
