#!/bin/bash

echo 0 | tee /proc/sys/kernel/randomize_va_space > /dev/null || error "Failed to disable ASLR."

cpu_vendor=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')

if [ "$cpu_vendor" = "GenuineIntel" ]; then
    if command -v x86_energy_perf_policy &>/dev/null; then
        x86_energy_perf_policy --turbo-enable 0 || error "Failed to disable Turbo Boost (Intel)."
    else
        error "x86_energy_perf_policy not found."
    fi
elif [ "$cpu_vendor" = "AuthenticAMD" ]; then
    if command -v wrmsr &>/dev/null; then
        modprobe msr || error "Failed to load msr module!"
        for core in $(seq 0 $(($(nproc --all) - 1))); do
            wrmsr -p"$core" 0x1a0 0x4000850089 || error "Failed to disable Turbo Boost (AMD) on core $core."
        done
    else
        error "wrmsr command not found! Install msr-tools package."
    fi
else
    error "Unknown CPU vendor!"
fi

cpupower frequency-set -g powersave >/dev/null || error "Failed to set CPU governor to powersave."

min_freq=$(cpupower frequency-info -l | awk 'NR==2{print $1}')
cpupower frequency-set --min "$min_freq" >/dev/null || error "Failed to set min CPU frequency to min."
cpupower frequency-set --max "$min_freq" >/dev/null || error "Failed to set max CPU frequency to min."

MEASURE_PRIORITY="nice -n -20"
