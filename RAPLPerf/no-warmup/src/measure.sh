# Multiplier to get values in joules
MULTIPLIER=6.103515625e-05

move_result() {
  local language="$1"
  local algorithm="$2"
  results_dir="../../../results"

  if [[ ! -d "${results_dir}/${language}/${algorithm}" ]]; then
    mkdir -p "${results_dir}/${language}/${algorithm}"
  fi

  mv "results.txt" "${results_dir}/${language}/${algorithm}/rapl.txt"
}

run_benchmark() {
  local language="$1"
  local algorithm="$2"
  local runs="$3"

  cd "./$language/$algorithm"
  
  for ((i = 0; i < runs; i++)); do
    echo "[INFO] Running $algorithm in $language (Run $((i + 1)))"

    perf stat --all-cpus --no-scale --no-big-num \
      --append --output results.txt \
      -e power/energy-pkg/,power/energy-ram/,power/energy-cores/ \
      -- make run || { echo "[ERROR] Failed to run $algorithm"; exit 1; }

    sleep 2s
  done

  sleep 1s
  move_result "$language" "$algorithm"
  cd "../.."
}

# Declare separate arrays for each language's algorithms

# C benchmarks
C_benchmarks=(
  "binary-trees"
  # "chameneos-redux" # Not Relevant
  "fannkuch-redux"
  "fasta"
  "k-nucleotide"
  "mandelbrot"
  "n-body"
  # "pidigits"  # Not Relevant
  "regex-redux"
  "reverse-complement"
  "spectral-norm"
)

# C# benchmarks
Csharp_benchmarks=(
  "binary-trees"
  # "chameneos-redux" # Not Relevant
  "fannkuch-redux"
  "fasta"
  "k-nucleotide"
  "mandelbrot"
  "n-body"
  # "pidigits"  # Not Relevant
  "regex-redux"
  "reverse-complement"
  "spectral-norm"
  # "thread-ring"  # Not Relevant
)

# C++ benchmarks
Cpp_benchmarks=(
  "binary-trees"
  # "chameneos-redux" # Not Relevant
  "fannkuch-redux"
  # "fasta" # Run this individually because it freezes sometimes
  "k-nucleotide"
  "mandelbrot"
  "n-body"
  # "pidigits"  # Not Relevant
  "regex-redux"
  "reverse-complement"
  "spectral-norm"
)

# Java benchmarks
Java_benchmarks=(
  "binary-trees"
  # "chameneos-redux" # Not Relevant
  "fannkuch-redux"
  "fasta"
  "k-nucleotide"
  "mandelbrot"
  "n-body"
  # "pidigits"  # Not Relevant
  "regex-redux"
  "reverse-complement"
  "spectral-norm"
)

# Rust benchmarks3
Rust_benchmarks=(
  "binary-trees"
  # "chameneos-redux" # Not Relevant
  "fannkuch-redux"
  "fasta"
  "k-nucleotide"
  "mandelbrot"
  "n-body"
  # "pidigits"  # Not Relevant
  "regex-redux"
  "reverse-complement"
  "spectral-norm"
)

# Map languages to their corresponding arrays
declare -A benchmarks_map=(
  ["C"]="C_benchmarks"
  ["C#"]="Csharp_benchmarks"
  ["C++"]="Cpp_benchmarks"
  ["Java"]="Java_benchmarks"
  ["Rust"]="Rust_benchmarks"
)

# Set the number of times each benchmark should be run
RUNS_PER_BENCHMARK=10  # Example: Each benchmark will be run 10 times

# Loop over each language and its corresponding algorithms sequentially
for language in "${!benchmarks_map[@]}"; do
  # Get the array name for the current language
  benchmarks_array="${benchmarks_map[$language]}"
  
  # Use eval to access the array dynamically
  eval "algorithms=(\"\${${benchmarks_array}[@]}\")"
  
  # Loop through each algorithm and run it sequentially
  for algorithm in "${algorithms[@]}"; do
    run_benchmark "$language" "$algorithm" "$RUNS_PER_BENCHMARK"
  done
done

