#!/bin/bash

BENCHMARK_SETS=("no-warmup" "warmup")
# BENCHMARK_LANGUAGES=("C" "C++" "C#" "Java" "Rust")
BENCHMARK_LANGUAGES=("C#" "Java")
BENCHMARKS=("binary-trees" "division-loop" "fannkuch-redux" "fasta" "k-nucleotide" "mandelbrot" "matrix-multiplication" "n-body" "polynomial-evaluation" "regex-redux" "reverse-complement" "spectral-norm")

PYTHON_FASTA_BENCHMARK="Python/fasta/fasta.python3-3.py"
KNUCLEOTIDE_INPUT="knucleotide-input25000000.txt"
REVCOMP_INPUT="revcomp-input25000000.txt"
REGEXREDUX_INPUT="regexredux-input5000000.txt"

COUNT=45
CACHE_MEASURE_FREQ_MS=500

# Ensure the script is run as root or with sudo
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] This script must be run as root or with sudo privileges."; exit 1;
fi

# Check if modprobe is available
if ! command -v modprobe &>/dev/null; then
    echo "[ERROR] 'modprobe' is not installed. Please install the 'kmod' package and try again."
    exit 1
fi

# Load msr module
if ! modprobe msr; then
    echo "[ERROR] Failed to load 'msr' kernel module. Ensure it is available and try again."
    exit 1
fi

bash optimizations.sh disable || { echo "[ERROR] Failed to disable OS optimizations. Exiting."; exit 1; }

# Check for Python interpreters
if command -v python3 &>/dev/null; then
    PYTHON="python3"
elif command -v python &>/dev/null; then
    PYTHON="python"
else
    echo "[Error] python is not installed."; exit 1;
fi

# Check if prerequisites input files exist in all benchmark sets
for SET in "${BENCHMARK_SETS[@]}"; do
    if [[ ! -f "$SET/src/$PYTHON_FASTA_BENCHMARK" ]]; then
        echo "[Error] File '$SET/src/$PYTHON_FASTA_BENCHMARK' doesn't exist. It's needed to generate inputs for other benchmarks"; exit 1;
    fi

    echo "[INFO] Creating input for K-nucleotide..."
    $PYTHON "$SET/src/$PYTHON_FASTA_BENCHMARK" 25000000 > "$SET/src/$KNUCLEOTIDE_INPUT" || { echo "[ERROR] Failed to generate $KNUCLEOTIDE_INPUT"; exit 1; }

    echo "[INFO] Creating input for Revcomp..."
    $PYTHON "$SET/src/$PYTHON_FASTA_BENCHMARK" 25000000 > "$SET/src/$REVCOMP_INPUT" || { echo "[ERROR] Failed to generate $REVCOMP_INPUT"; exit 1; }

    echo "[INFO] Creating input for Regexredux..."
    $PYTHON "$SET/src/$PYTHON_FASTA_BENCHMARK" 5000000 > "$SET/src/$REGEXREDUX_INPUT" || { echo "[ERROR] Failed to generate $REGEXREDUX_INPUT"; exit 1; }
done
# Generating input is cpu intensive and we should sleep for 60s
# here so we can drop down the temperature for the first benchmark
echo "[INFO] Sleeping for 60 seconds before starting the first measurement."; sleep 60s;

# Run benchmarks
for SET in "${BENCHMARK_SETS[@]}"; do
    for LANGUAGE in "${BENCHMARK_LANGUAGES[@]}"; do
        for BENCHMARK in "${BENCHMARKS[@]}"; do
            benchmark_dir="$SET/src/$LANGUAGE/$BENCHMARK"

            if [[ ! -d "$benchmark_dir" ]]; then
                echo "[ERROR] Missing benchmark directory '$benchmark_dir'."
                continue
            fi

            pushd "$benchmark_dir" >/dev/null
            if nice -n -20 make measure COUNT="$COUNT" CACHE_MEASURE_FREQ_MS="$CACHE_MEASURE_FREQ_MS"; then
                latest_measurement=$(find . -maxdepth 1 -name '*.csv' -printf '%T+ %p\n' | sort -r | head -n 1 | cut -d' ' -f2-)
                if [[ -f "$latest_measurement" ]]; then
                    results_dir="../../../results/$LANGUAGE/$BENCHMARK"
                    echo "[INFO] Finished measuring benchmark. Moving results to '$results_dir'."
                    mkdir -p "$results_dir"
                    mv "$latest_measurement" "$results_dir/rapl.csv"
                    mv "cache.txt" "$results_dir/cache.txt"
                else
                    echo "[WARNING] No measurement file generated for '$benchmark_dir'."
                fi
                # We should sleep for 60s after each benchmark to drop down
                # the temperature for the next benchmark
                echo "[INFO] Sleeping for 60 seconds before starting next measurement."; sleep 60s;
            else
                echo "[WARNING] Failed to measure benchmark in '$benchmark_dir'. Skipping."
            fi
            popd >/dev/null
        done
    done
done
