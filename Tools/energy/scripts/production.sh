#!/bin/bash

cpupower frequency-set -g performance 1>/dev/null || error "Failed to set CPU governor to performance."

min_freq=$(cpupower frequency-info -l | awk 'NR==2{print $1}')
max_freq=$(cpupower frequency-info -l | awk 'NR==2{print $2}')
cpupower frequency-set -d "$min_freq" 1>/dev/null || error "Failed to set min CPU frequency to min."
cpupower frequency-set -u "$max_freq" 1>/dev/null || error "Failed to set max CPU frequency to max."

if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo || error "Failed to enable Turbo Boost (Intel)."
elif command -v wrmsr &>/dev/null; then
    for core in $(seq 0 $(nproc --all)); do
        wrmsr -p"$core" 0x1a0 0x850089 || error "Failed to enable Turbo Boost (AMD) on core $core."
    done
fi

echo 2 > /proc/sys/kernel/randomize_va_space || error "Failed to enable ASLR."
