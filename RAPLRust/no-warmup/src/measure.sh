# Multiplier to get values in joules
MULTIPLIER=6.103515625e-05

move_result() {
  local language="$1"
  local algorithm="$2"
  latest_result=$(find . -maxdepth 1 -name '*.csv' -printf '%T+ %p\n' | sort -r | head -n 1 | cut -d' ' -f2-)
  timestamp=$(date +%s)
  results_dir="../../../results"

  if [[ ! -d "${results_dir}/${language}/${algorithm}" ]]; then
    mkdir -p "${results_dir}/${language}/${algorithm}"
  fi

  mv "$latest_result" "${results_dir}/${language}/${algorithm}/rapl.csv"
}

run_benchmark() {
  local language="$1"
  local algorithm="$2"

  cd "./$language/$algorithm" || { echo "[ERROR] Failed to change directory to $language/$algorithm"; exit 1; }
  make measure || { echo "[ERROR] Failed to measure"; exit 1; }
  sleep 1s
  move_result "$language" "$algorithm"
  cd "../.." || { echo "[ERROR] Failed to navigate back"; exit 1; }
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
  # "pidigits" # Not Relevant
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
  # "pidigits" # Not Relevant
  "regex-redux"
  "reverse-complement"
  "spectral-norm"
  # "thread-ring" # Not Relevant
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
  # "pidigits" # Not Relevant
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
  # "pidigits" # Not Relevant
  "regex-redux"
  "reverse-complement"
  "spectral-norm"
)

# Rust benchmarks
Rust_benchmarks=(
  "binary-trees"
  # "chameneos-redux" # Not Relevant
  "fannkuch-redux"
  "fasta"
  "k-nucleotide"
  "mandelbrot"
  "n-body"
  # "pidigits" # Not Relevant
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

# Loop over each language and its corresponding algorithms
for language in "${!benchmarks_map[@]}"; do
  # Access the correct array for the current language
  benchmarks_array="${benchmarks_map[$language]}"
  eval "algorithms=(\"\${${benchmarks_array}[@]}\")"

  for algorithm in "${algorithms[@]}"; do
    run_benchmark "$language" "$algorithm"
  done
done
