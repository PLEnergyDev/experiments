#!/bin/bash

# Usage: ./lab-setup.sh [enable|restore|help]

backup_dir="/tmp/lab_backup"

error_msg() {
  echo "Error: $1" >&2
  exit 1
}

usage() {
  echo "Usage: $0 [enable|restore|help]"
  exit 1
}

[ "$(id -u)" -ne 0 ] && error_msg "Run as root."

case "$1" in
  enable)
    if [ -d "$backup_dir" ]; then
      error_msg "Backup dir already exists. Use 'restore' first or remove $backup_dir."
    fi
    mkdir -p "$backup_dir" || error_msg "Unable to create backup directory."

    # Save and disable ASLR
    cat /proc/sys/kernel/randomize_va_space > "$backup_dir/aslr"
    echo 0 > /proc/sys/kernel/randomize_va_space 2>/dev/null || error_msg "Failed to disable ASLR."

    # Save and disable Turbo Boost
    cores=$(awk '/processor/{print $3}' /proc/cpuinfo)
    mkdir -p "$backup_dir/turbo_states"
    for core in $cores; do
      state=$(rdmsr -p${core} 0x1a0 -f 38:38)
      echo "$state" > "$backup_dir/turbo_states/core_${core}"
      wrmsr -p${core} 0x1a0 0x4000850089 || error_msg "Failed to disable Turbo Boost on core ${core}."
    done

    # Save the current governor and frequencies
    current_governor=$(cpupower frequency-info | awk -F'"' '/governor/ {print $2}' | tr -d '\n')
    echo "$current_governor" > "$backup_dir/current_governor"

    cpupower frequency-info > /dev/null 2>&1 || error_msg "cpupower tool not available. Install it first."
    current_min=$(cpupower frequency-info -l | awk 'NR==2{print $1}') # Get the minimum frequency supported
    current_max=$(cpupower frequency-info -l | awk 'NR==2{print $2}') # Get the maximum frequency supported

    echo "$current_min" > "$backup_dir/cpu_min_freq"
    echo "$current_max" > "$backup_dir/cpu_max_freq"

    # Set governor to powersave and pin to minimum frequency
    cpupower frequency-set -g powersave || error_msg "Failed to set CPU governor to powersave."
    cpupower frequency-set -d "$current_min" || error_msg "Failed to set minimum CPU frequency."
    cpupower frequency-set -u "$current_min" || error_msg "Failed to set maximum CPU frequency."

    echo "Lab environment enabled."
    ;;

  restore)
    if [ ! -d "$backup_dir" ]; then
      error_msg "No backup found. Enable first."
    fi

    # Restore ASLR
    if [ -f "$backup_dir/aslr" ]; then
      cat "$backup_dir/aslr" > /proc/sys/kernel/randomize_va_space
    fi

    # Restore Turbo Boost
    if [ -d "$backup_dir/turbo_states" ]; then
      cores=$(awk '/processor/{print $3}' /proc/cpuinfo)
      for core in $cores; do
        state_file="$backup_dir/turbo_states/core_${core}"
        if [ -f "$state_file" ]; then
          state=$(cat "$state_file")
          if [[ $state -eq 1 ]]; then
            wrmsr -p${core} 0x1a0 0x4000850089 || error_msg "Failed to disable Turbo Boost on core ${core}."
          else
            wrmsr -p${core} 0x1a0 0x850089 || error_msg "Failed to enable Turbo Boost on core ${core}."
          fi
        fi
      done
    fi

    # Restore CPU frequencies and governor
    if [ -f "$backup_dir/cpu_min_freq" ] && [ -f "$backup_dir/cpu_max_freq" ] && [ -f "$backup_dir/current_governor" ]; then
      original_min=$(cat "$backup_dir/cpu_min_freq")
      original_max=$(cat "$backup_dir/cpu_max_freq")
      original_governor=$(cat "$backup_dir/current_governor")

      cpupower frequency-set -g "$original_governor" || error_msg "Failed to restore CPU governor to $original_governor."
      cpupower frequency-set -d "$original_min" || error_msg "Failed to restore minimum CPU frequency."
      cpupower frequency-set -u "$original_max" || error_msg "Failed to restore maximum CPU frequency."
    fi

    rm -rf "$backup_dir"
    echo "Restored previous settings."
    ;;

  help|*)
    usage
    ;;
esac
