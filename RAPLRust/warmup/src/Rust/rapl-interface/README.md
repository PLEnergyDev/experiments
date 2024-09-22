# rapl-interface

This is a library and executable project for reading the RAPL registers on Intel and AMD processors written in Rust.

The supported operating systems are Linux and Windows.

The repository also contains several benchmarks for testing the library.

## GitHub Actions

An issue currently too is that MSR's are not accessible with GitHub Actions, likely due to that it runs under Docker.

## Windows

Currently this does not work on Windows because `readmsr` requires kernel access. It will require a kernel driver to make it work. Intel Power Gadget can support it by design but it will only be for Intel processors in that case.

Solution found: Use LibreHardwareMonitor's driver. It is open source and can be used for this purpose.

## RAPL test

https://github.com/djselbeck/rapl-read-ryzen

https://me.sakana.moe/2023/09/06/measuring-cpu-power-consumption/

https://github.com/hubblo-org/windows-rapl-driver

https://github.com/amd/amd_energy

## Test for CPU

https://github.com/RRZE-HPC/likwid/issues/373

List the CPU's MSR's on Linux.

`ls -la /dev/cpu/*/msr`

Enable MSR.

`sudo modprobe msr`

## Install driver on Windows

Use command prompt as administrator.

Query for all drivers:

`sc query type= driver`

Create:

`sc create rapl type= kernel binPath= "full path to driver here"`

Start:

`sc start rapl`

Stop:

`sc stop rapl`

Delete:

`sc delete rapl`

## How to run benchmarks

### how to run with runBench.sh (only works on linux)
1. Build the rapl code with `cargo build --release` from root
2. Call the script with `sudo sh runBench.sh` (use taskset for CPU affinity https://manpages.ubuntu.com/manpages/trusty/man1/taskset.1.html)
3. The results will be put in csv files in the results folder after the script is finished 

note: running the script from SSH requires the usage of tools like nohup:
``` sudo nohup sh runBench.sh ```

### how to run Fibonacci sequence with python
1. Build the rapl code with `cargo build --release` from root
2. Download, install and start libreHardwareMonitor (not required for linux)
3. Call the benchmarking code (with administrative priviliges):
    - ``` python '.\benchmarks\fibonacci sequence\bench.py' ```
4. The results can be found in "test.csv" in the root folder

### Disabling raspberry or kill script
The `runBench.sh` has two optional arguments, the first is for disabling the interaction with the raspberry pi the secound is for disabling the script that stops services while running the benchmarks.

- Disable stopping services: `sh runBench.sh true false`
- Disable Raspberry interaction: `sh runBench.sh false`
- Disable both: `sh runBench false false`
