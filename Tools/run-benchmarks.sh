#!/bin/bash
export DOTNET_ROOT="/usr/share/dotnet"

BASE_DIR="$1"
LAB_SETUP="prod"
VALID_CONFIGS=("no-warmup" "warmup")
CONFIGS=("no-warmup" "warmup")
LANGUAGES=()
BENCHMARKS=()
PYTHON_FASTA="fasta.py"
KNUCLEOTIDE_INPUT="knucleotide-input25000000.txt"
REVCOMP_INPUT="revcomp-input25000000.txt"
REGEXREDUX_INPUT="regexredux-input5000000.txt"

# Default values for optional arguments
COUNT=45
CACHE_MEASURE_FREQ_MS=500

error_msg() {
  echo "[ERROR] $1" >&2
  exit 1
}

usage() {
    printf "Usage: sudo -E bash $0 base_dir [-c CONFIGS] [-l LANGUAGES] [-b BENCHMARKS] [--lab] [-n <count>] [-f <freq_ms>]\n\n"
}

help() {
    usage
    cat << HELP
positional arguments:
  base_dir                    The base path for all benchmarks.

options:
  -c, --configs CONFIGS       Comma-separeted list of configs. Allowed values: 'no-warmup', 'warmup' (or both).
  -l, --languages LANGUAGES   Comma-separated list of languages. If omitted, all languages found in the base directory are used.
  -b, --benchmarks BENCHMARKS Comma-separated list of benchmarks. If omitted, all benchmarks found in the language directories are used.
  --lab                       Optional: Specifies whether the benchmarks should run in lab mode. Defaults to production.
  -n, --count COUNT           Optional: Number of times benchmarks should run. Default: 45.
  -f, --freq-ms FREQ_MS       Optional: Frequency in milliseconds for perf measurement. Default: 500.
  -h, --help                  Print this help message.
HELP
    exit 0
}

prod() {
  echo "[INFO] Switching to Production Environment..."

  # Set governor to performance
  cpupower frequency-set -g performance 1>/dev/null || error_msg "Failed to set CPU governor to performance."

  # Get max frequency and set it
  min_freq=$(cpupower frequency-info -l | awk 'NR==2{print $1}')
  max_freq=$(cpupower frequency-info -l | awk 'NR==2{print $2}')
  cpupower frequency-set -d "$min_freq" 1>/dev/null || error_msg "Failed to set min CPU frequency to min."
  cpupower frequency-set -u "$max_freq" 1>/dev/null || error_msg "Failed to set max CPU frequency to max."

  # Enable Turbo Boost (Intel and AMD)
  if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo || error_msg "Failed to enable Turbo Boost (Intel)."
  elif command -v wrmsr &>/dev/null; then
    for core in $(seq 0 $(nproc --all)); do
      wrmsr -p"$core" 0x1a0 0x850089 || error_msg "Failed to enable Turbo Boost (AMD) on core $core."
    done
  fi

  # Enable ASLR
  echo 2 > /proc/sys/kernel/randomize_va_space || error_msg "Failed to enable ASLR."

  echo "[SUCCESS] Production environment enabled."
}

lab() {
  echo "[INFO] Switching to Lab Environment..."

  # Disable ASLR
  echo 0 > /proc/sys/kernel/randomize_va_space || error_msg "Failed to disable ASLR."

  # Disable Turbo Boost (Intel and AMD)
  if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo || error_msg "Failed to disable Turbo Boost (Intel)."
  elif command -v wrmsr &>/dev/null; then
    for core in $(seq 0 $(nproc --all)); do
      wrmsr -p"$core" 0x1a0 0x4000850089 || error_msg "Failed to disable Turbo Boost (AMD) on core $core."
    done
  fi

  # Set governor to powersave
  cpupower frequency-set -g powersave 1>/dev/null || error_msg "Failed to set CPU governor to powersave."

  # Get min frequency and set it
  min_freq=$(cpupower frequency-info -l | awk 'NR==2{print $1}')
  cpupower frequency-set -d "$min_freq" 1>/dev/null || error_msg "Failed to set min CPU frequency to min."
  cpupower frequency-set -u "$min_freq" 1>/dev/null || error_msg "Failed to set max CPU frequency to min."

  echo "[SUCCESS] Lab environment enabled."
}

# Ensure system has correct dependencies
if ! command -v modprobe &>/dev/null; then
    error_msg "'modprobe' is not installed. Please install the 'kmod' package and try again."
    exit 1
fi

# Ensure cpupower exists
if ! command -v cpupower &>/dev/null; then
    error_msg "'cpupower' not found. Install 'linux-tools' or equivalent package."
fi

if ! modprobe msr; then
    error_msg "Failed to load 'msr' kernel module. Ensure it is available and try again."
    exit 1
fi

if command -v python3 &>/dev/null; then
    PYTHON="python3"
elif command -v python &>/dev/null; then
    PYTHON="python"
else
    error_msg "python is not installed."
    exit 1
fi

# Ensure correct usage of the script
if [[ $EUID -ne 0 ]]; then
    usage
    error_msg "This script must be run with sudo -E."
    exit 1
fi

# Parse arguments
OPTIONS=$(getopt -o c:l:b:s:n:f:h --long config:,language:,benchmark:,lab,count:,freq-ms:,help -- "$@")
if [[ $? -ne 0 ]]; then
  exit 1
fi

eval set -- "$OPTIONS"

while true; do
  case "$1" in
    -c|--configs)
      IFS=',' read -r -a CONFIGS <<< "$2"
      shift 2
      ;;
    -l|--languages)
      IFS=',' read -r -a LANGUAGES <<< "$2"
      shift 2
      ;;
    -b|--benchmarks)
      IFS=',' read -r -a BENCHMARKS <<< "$2"
      shift 2
      ;;
    -s|--lab)
      LAB_SETUP="lab"
      lab
      shift
      ;;
    -n|--count)
      COUNT="$2"
      shift 2
      ;;
    -f|--freq-ms)
      CACHE_MEASURE_FREQ_MS="$2"
      shift 2
      ;;
    -h|--help)
      help
      exit 0
      ;;
    --)
      shift
      break
      ;;
  esac
done

if [[ -z "$BASE_DIR" ]]; then
    usage
    error_msg "Base directory must be specified."
    exit 1
fi

if [[ ! -d "$BASE_DIR" ]]; then
    usage
    error_msg "The specified base directory does not exist: $BASE_DIR"
    exit 1
fi

# Determine if we're in production mode
if [[ "$LAB_SETUP" == "prod" ]]; then
  prod
fi

# Determine script's directory (absolute path)
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PYTHON_FASTA="$SCRIPT_DIR/fasta.py"

# Ensure PYTHON_FASTA exists
if [[ ! -f "$PYTHON_FASTA" ]]; then
    error_msg "Python fasta script not found at: $PYTHON_FASTA. Exiting."
    exit 1
fi

# Auto-detect available languages if none provided
if [[ ${#LANGUAGES[@]} -eq 0 ]]; then
    echo "[INFO] No languages specified. Fetching all available languages from '$BASE_DIR'."
    LANGUAGES=($(find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort))
    if [[ ${#LANGUAGES[@]} -eq 0 ]]; then
        error_msg "No languages found in '$BASE_DIR'. Exiting."
        exit 1
    fi
fi

# Auto-detect available benchmarks if none provided (avoiding duplicates)
if [[ ${#BENCHMARKS[@]} -eq 0 ]]; then
    echo "[INFO] No benchmarks specified. Fetching all unique benchmarks."
    declare -A BENCHMARK_SET

    for lang in "${LANGUAGES[@]}"; do
        if [[ -d "$BASE_DIR/$lang" ]]; then
            for benchmark in $(find "$BASE_DIR/$lang" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort); do
                BENCHMARK_SET["$benchmark"]=1
            done
        fi
    done

    # Convert associative array to indexed array (unique values)
    BENCHMARKS=("${!BENCHMARK_SET[@]}")

    if [[ ${#BENCHMARKS[@]} -eq 0 ]]; then
        error_msg "No benchmarks found under any language directory. Exiting."
        exit 1
    fi
fi

echo "[INFO] Shuffling all variables..."
CONFIGS=($(shuf -e "${CONFIGS[@]}"))
LANGUAGES=($(shuf -e "${LANGUAGES[@]}"))
BENCHMARKS=($(shuf -e "${BENCHMARKS[@]}"))

CPUINFO_MIN_FREQ=$(cat /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_min_freq)
CPUINFO_MAX_FREQ=$(cat /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq)

SCALING_DRIVER=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_driver)
SCALING_DRIVER_STATUS=$(cat /sys/devices/system/cpu/$SCALING_DRIVER/status 2>/dev/null || echo "N/A")
SCALING_GOVERNOR=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor)
SCALING_MIN_FREQ=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq)
SCALING_MAX_FREQ=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq)

# Read ASLR and Turbo Boost values safely
ASLR_VALUE=$(cat /proc/sys/kernel/randomize_va_space 2>/dev/null || echo "N/A")
TURBO_BOOST_VALUE=$(cat /sys/devices/system/cpu/$SCALING_DRIVER/no_turbo 2>/dev/null || echo "N/A")

# Convert ASLR value to a human-readable format
case "$ASLR_VALUE" in
    0) ASLR_STATUS="Disabled (No randomization)" ;;
    1) ASLR_STATUS="Enabled (Partial randomization)" ;;
    2) ASLR_STATUS="Fully Enabled (Full randomization)" ;;
    *) ASLR_STATUS="Unknown" ;;
esac

# Convert Turbo Boost value to a user-friendly format
if [[ "$TURBO_BOOST_VALUE" == "1" ]]; then
    TURBO_BOOST_STATUS="Disabled"
elif [[ "$TURBO_BOOST_VALUE" == "0" ]]; then
    TURBO_BOOST_STATUS="Enabled"
else
    TURBO_BOOST_STATUS="Unknown"
fi

cat << HELP
========== Running With: ==========
  Base Directory:     $BASE_DIR
  Experiment Confs:   ${CONFIGS[*]}
  Languages:          ${LANGUAGES[*]}
  Benchmarks:         ${BENCHMARKS[*]}
  Experiment Setup:   $LAB_SETUP
  Iteration Count:    $COUNT
  Measure Freq (ms):  $CACHE_MEASURE_FREQ_MS
========== Current Setup: =========
  Hardware Freq (Hz): $CPUINFO_MIN_FREQ - $CPUINFO_MAX_FREQ
  Scaling Driver:     $SCALING_DRIVER = $SCALING_DRIVER_STATUS
  Scaling Governor:   $SCALING_GOVERNOR
  Scaling Freq (Hz):  $SCALING_MIN_FREQ - $SCALING_MAX_FREQ
  Turbo Boost:        $TURBO_BOOST_STATUS
  ASLR:               $ASLR_STATUS
===================================

HELP

# Check if prerequisite input files exist
if [[ ! -f "$BASE_DIR/$KNUCLEOTIDE_INPUT" ]]; then
    echo "[INFO] Creating input for K-nucleotide..."
    $PYTHON "$PYTHON_FASTA" 25000000 > "$BASE_DIR/$KNUCLEOTIDE_INPUT" || { error_msg "Failed to generate $BASE_DIR/$KNUCLEOTIDE_INPUT"; exit 1; }
else
    echo "[INFO] Input for K-nucleotide already exists. Skipping..."
fi

if [[ ! -f "$BASE_DIR/$REVCOMP_INPUT" ]]; then
    echo "[INFO] Creating input for Revcomp..."
    $PYTHON "$PYTHON_FASTA" 25000000 > "$BASE_DIR/$REVCOMP_INPUT" || { error_msg "Failed to generate $BASE_DIR/$REVCOMP_INPUT"; exit 1; }
else
    echo "[INFO] Input for Revcomp already exists. Skipping..."
fi

if [[ ! -f "$BASE_DIR/$REGEXREDUX_INPUT" ]]; then
    echo "[INFO] Creating input for Regexredux..."
    $PYTHON "$PYTHON_FASTA" 5000000 > "$BASE_DIR/$REGEXREDUX_INPUT" || { error_msg "Failed to generate $BASE_DIR/$REGEXREDUX_INPUT"; exit 1; }
else
    echo "[INFO] Input for Regexredux already exists. Skipping..."
fi 

echo "[INFO] Sleeping for 60 seconds before starting the first measurement."
sleep 10s

# Change to the base directory
cd "$BASE_DIR" || { error_msg "Failed to change directory to $BASE_DIR"; exit 1; }

# Run benchmarks
for MODE in "${CONFIGS[@]}"; do
    for LANGUAGE in "${LANGUAGES[@]}"; do
        for BENCHMARK in "${BENCHMARKS[@]}"; do
            benchmark_dir="$LANGUAGE/$BENCHMARK"

            if [[ ! -d "$benchmark_dir" ]]; then
                echo "[WARNING] Missing benchmark directory '$benchmark_dir'. Skipping..."
                continue
            fi

            pushd "$benchmark_dir" >/dev/null
            if [[ "$LAB_SETUP" == "lab" ]]; then
                COMMAND="nice -n -20 make measure MODE=\"$MODE\" COUNT=\"$COUNT\" CACHE_MEASURE_FREQ_MS=\"$CACHE_MEASURE_FREQ_MS\""
            else
                COMMAND="make measure MODE=\"$MODE\" COUNT=\"$COUNT\" CACHE_MEASURE_FREQ_MS=\"$CACHE_MEASURE_FREQ_MS\""
            fi
            
            if eval $COMMAND; then
                latest_measurement=$(find . -maxdepth 1 -name '*.csv' -printf '%T+ %p\n' | sort -r | head -n 1 | cut -d' ' -f2-)
                if [[ -f "$latest_measurement" ]]; then
                    results_dir="../../../results/$MODE/$LANGUAGE/$BENCHMARK"
                    echo "[INFO] Finished measuring benchmark. Moving results to '$results_dir'."
                    mkdir -p "$results_dir"
                    mv "$latest_measurement" "$results_dir/rapl.csv"
                    mv "cache.txt" "$results_dir/cache.txt"
                else
                    echo "[WARNING] No measurement file generated for '$benchmark_dir'."
                fi
                echo "[INFO] Sleeping for 60 seconds before starting next measurement."
                sleep 60s
            else
                echo "[WARNING] Failed to measure benchmark in '$benchmark_dir'. Skipping..."
            fi
            popd >/dev/null
        done
    done
done
