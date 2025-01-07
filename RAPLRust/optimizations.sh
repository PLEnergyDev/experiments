#!/bin/bash

# Ensure the script is run as root or with sudo
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] This script must be run as root or with sudo privileges."; exit 1;
fi

if [[ -z $(which rdmsr) || -z $(which wrmsr) ]]; then
    echo "[ERROR] msr-tools is not installed. Run 'sudo apt-get install msr-tools' to install it." >&2; exit 1;
fi

if [[ ! -z $1 && $1 != "enable" && $1 != "disable" ]]; then
    echo "[INFO] Invalid argument: $1" >&2
    echo ""
    echo "Usage: $(basename $0) [disable|enable]"
    exit 1
fi

cores=$(cat /proc/cpuinfo | grep processor | awk '{print $3}')
for core in $cores; do
    if [[ $1 == "disable" ]]; then
        # Disable turbo boost
        wrmsr -p${core} 0x1a0 0x4000850089
    fi
    if [[ $1 == "enable" ]]; then
        # Enable turbo boost
        wrmsr -p${core} 0x1a0 0x850089
    fi
    # Check turbo state
    state=$(rdmsr -p${core} 0x1a0 -f 38:38)
    if [[ $state -eq 1 ]]; then
        echo "[INFO] core ${core}: turbo disabled"
    else
        echo "[INFO] core ${core}: turbo enabled"
    fi
done

# Adjust CPU frequency scaling for all cores
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_*; do
    if [[ $1 == "disable" ]]; then
        # Set CPU to minimum frequency
        min_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq)
        echo $min_freq | tee $cpu 2>/dev/null >/dev/null
    fi
    if [[ $1 == "enable" ]]; then
        # Set CPU to maximum frequency
        max_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
        echo $max_freq | tee $cpu 2>/dev/null >/dev/null
    fi
done

# Adjust ASLR settings
if [[ $1 == "disable" ]]; then
    echo 0 | tee /proc/sys/kernel/randomize_va_space >/dev/null
    echo "[INFO] Memory layout randomization (ASLR) disabled."
fi
if [[ $1 == "enable" ]]; then
    echo 2 | tee /proc/sys/kernel/randomize_va_space >/dev/null
    echo "[INFO] Memory layout randomization (ASLR) enabled."
fi

# Report current frequency scaling setting
if [[ $1 == "disable" ]]; then
    echo "[INFO] CPU frequency pinned to minimum."
else
    echo "[INFO] CPU frequency restored to maximum."
fi
