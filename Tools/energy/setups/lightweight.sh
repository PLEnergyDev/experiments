#!/bin/bash

cpupower frequency-set -g performance >/dev/null || error "Failed to set CPU governor to performance."

min_freq=$(cpupower frequency-info -l | awk 'NR==2{print $1}')
max_freq=$(cpupower frequency-info -l | awk 'NR==2{print $2}')
cpupower frequency-set --min "$min_freq" >/dev/null || error "Failed to set min CPU frequency to min."
cpupower frequency-set --max "$max_freq" >/dev/null || error "Failed to set max CPU frequency to max."

if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    if command -v x86_energy_perf_policy &>/dev/null; then
        x86_energy_perf_policy --turbo-enable 1 || error "Failed to enable Turbo Boost (Intel)."
    else
        echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo || error "Failed to enable Turbo Boost (Intel)."
    fi

elif command -v wrmsr &>/dev/null; then
    modprobe msr || error "Failed to load msr module!"
    for core in $(seq 0 $(($(nproc --all) - 1))); do
        wrmsr -p"$core" 0x1a0 0x850089 || error "Failed to enable Turbo Boost (AMD) on core $core."
    done
fi

echo 2 > /proc/sys/kernel/randomize_va_space || error "Failed to enable ASLR."

# we could even try to disable some processes here
