#!/bin/bash

SCRIPT_NAME=energy

MEASURE_DRIVER=
MEASURE_DRIVER_STATUS=
MEASURE_GOVERNOR=
MEASURE_MIN_FREQ=
MEASURE_MAX_FREQ=
MEASURE_TURBO=
MEASURE_ASLR=

error() {
    echo -e "\nError: $1" >&2
    exit 1
}

warning() {
    echo -e "\nWarning: $1"
}

info() {
    echo -e "\nInfo: $1"
}

set_measure_variables() {
    MEASURE_DRIVER=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_driver)
    if [[ "$MEASURE_DRIVER" == "amd-pstate-epp" ]]; then
        MEASURE_DRIVER="amd_pstate"
    fi
    MEASURE_DRIVER_STATUS=$(cat /sys/devices/system/cpu/$MEASURE_DRIVER/status 2>/dev/null || echo "N/A")
    MEASURE_GOVERNOR=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor)
    MEASURE_MIN_FREQ=$(( $(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq) / 1000 ))
    MEASURE_MAX_FREQ=$(( $(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq) / 1000 ))

    MEASURE_ASLR=$(cat /proc/sys/kernel/randomize_va_space 2>/dev/null || echo "N/A")
    MEASURE_TURBO=$(cat /sys/devices/system/cpu/$MEASURE_DRIVER/no_turbo 2>/dev/null || echo "N/A")

    case "$MEASURE_ASLR" in
        0) MEASURE_ASLR="Disabled (No randomization)" ;;
        1) MEASURE_ASLR="Enabled (Partial randomization)" ;;
        2) MEASURE_ASLR="Fully Enabled (Full randomization)" ;;
        *) MEASURE_ASLR="Unknown" ;;
    esac

    if ! cpupower frequency-info | grep "Supported: yes" &>/dev/null; then
        MEASURE_TURBO="Unknown"
    elif cpupower frequency-info | grep "Active: yes" &>/dev/null; then
        MEASURE_TURBO="Enabled"
    else
        MEASURE_TURBO="Disabled"
    fi
}
