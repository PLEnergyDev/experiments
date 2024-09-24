# Multiplier to get values in joules
MULTIPLIER=6.103515625e-05

compile_benchmark() {
  local language="$1"
  local algorithm="$2"
  local target_dir="./$language/$algorithm"

  # Check if target binary or class file already exists
  if [[ -f "$target_dir/$algorithm" || -f "$target_dir/$algorithm.class" ]]; then
    echo "[INFO] $algorithm for $language is already compiled. Skipping."
    return 0
  fi

  cd "$target_dir" || { echo "[ERROR] Failed to navigate to $target_dir"; return 1; }
  
  # Clean and compile
  make clean || { echo "[ERROR] Failed to clean $algorithm"; return 1; }
  make || { echo "[ERROR] Failed to compile $algorithm"; return 1; }
  
  cd "../../" || { echo "[ERROR] Failed to navigate back"; return 1; }
}

# Declare supported algorithms for each language using plain arrays

# C benchmarks
C_benchmarks=(
  "binary-trees"
  "chameneos-redux"
  "fannkuch-redux"
  "fasta"
  "k-nucleotide"
  "mandelbrot"
  "n-body"
  "pidigits"
  "regex-redux"
  "reverse-complement"
  "spectral-norm"
)

# C# benchmarks
Csharp_benchmarks=(
  "binary-trees"
  "chameneos-redux"
  "fannkuch-redux"
  "fasta"
  "k-nucleotide"
  "mandelbrot"
  "n-body"
  "pidigits"
  "regex-redux"
  "reverse-complement"
  "spectral-norm"
  "thread-ring"
)

# C++ benchmarks
Cpp_benchmarks=(
  "binary-trees"
  "chameneos-redux"
  "fannkuch-redux"
  "fasta"
  "k-nucleotide"
  "mandelbrot"
  "n-body"
  "pidigits"
  "regex-redux"
  "reverse-complement"
  "spectral-norm"
)

# Java benchmarks
Java_benchmarks=(
  "binary-trees"
  "fannkuch-redux"
  "fasta"
  "k-nucleotide"
  "mandelbrot"
  "n-body"
  "regex-redux"
  "reverse-complement"
  "spectral-norm"
)

# Rust benchmarks
Rust_benchmarks=(
  "binary-trees"
  "fannkuch-redux"
  "fasta"
  "k-nucleotide"
  "mandelbrot"
  "n-body"
  "pidigits"
  "regex-redux"
  "reverse-complement"
  "spectral-norm"
)

# Map language names to their respective arrays
declare -A benchmarks_map=(
  ["C"]="C_benchmarks"
  ["C#"]="Csharp_benchmarks"
  ["C++"]="Cpp_benchmarks"
  ["Java"]="Java_benchmarks"
  ["Rust"]="Rust_benchmarks"
)

# Compile benchmarks in parallel, and limit the number of parallel jobs
max_jobs=4
job_count=0

for language in "${!benchmarks_map[@]}"; do
  # Get the array name and use indirect reference to access the array
  benchmarks_array="${benchmarks_map[$language]}"
  eval "algorithms=(\"\${${benchmarks_array}[@]}\")"  # Use eval to expand the array reference

  for algorithm in "${algorithms[@]}"; do
    # Run compile_benchmark in the background
    compile_benchmark "$language" "$algorithm" &

    # Control the number of parallel jobs
    ((job_count++))
    if ((job_count >= max_jobs)); then
      wait -n  # Wait for any job to finish before starting a new one
      ((job_count--))
    fi
  done
done

# Wait for all background jobs to finish
wait

echo "All benchmarks have been compiled."
