#!/bin/bash

echo 0 > /proc/sys/kernel/randomize_va_space || error "Failed to disable ASLR."

if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo || error "Failed to disable Turbo Boost (Intel)."
elif command -v wrmsr &>/dev/null; then
    for core in $(seq 0 $(nproc --all)); do
        wrmsr -p"$core" 0x1a0 0x4000850089 || error "Failed to disable Turbo Boost (AMD) on core $core."
    done
fi

cpupower frequency-set -g powersave 1>/dev/null || error "Failed to set CPU governor to powersave."

min_freq=$(cpupower frequency-info -l | awk 'NR==2{print $1}')
cpupower frequency-set -d "$min_freq" 1>/dev/null || error "Failed to set min CPU frequency to min."
cpupower frequency-set -u "$min_freq" 1>/dev/null || error "Failed to set max CPU frequency to min."
