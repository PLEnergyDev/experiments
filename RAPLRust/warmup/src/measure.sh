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
  sleep 60s
  move_result "$language" "$algorithm" || { echo "[ERROR] Failed to move result"; exit 1; }
  cd "../.." || { echo "[ERROR] Failed to navigate back"; exit 1; }
}

benchmarks=(
  "binary-trees"
  "division-loop"
  "fannkuch-redux"
  "fasta"
  "k-nucleotide"
  "mandelbrot"
  "matrix-multiplication"
  "n-body"
  "polynomial-evaluation"
  "regex-redux"
  "reverse-complement"
  "spectral-norm"
)

declare -A benchmarks_map=(
  ["C"]="benchmarks"
  ["C#"]="benchmarks"
  ["C++"]="benchmarks"
  ["Java"]="benchmarks"
  ["Rust"]="benchmarks"
)

for language in "${!benchmarks_map[@]}"; do
  benchmarks_array="${benchmarks_map[$language]}"
  eval "algorithms=(\"\${${benchmarks_array}[@]}\")"

  for algorithm in "${algorithms[@]}"; do
    run_benchmark "$language" "$algorithm"
  done
done
