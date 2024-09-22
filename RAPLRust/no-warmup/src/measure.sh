# multiplier to get values in joules 6.103515625e-05

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

  cd "./$language/$algorithm"
  make measure || { echo "[ERROR] Failed to measure"; exit 1; }
  sleep 1s
  move_result "$language" "$algorithm"
  cd "../.."
}

run_benchmark "C" "binary-trees"
run_benchmark "C" "chameneos-redux"
# run_benchmark "C" "division-loop" # Not Implemented
run_benchmark "C" "fannkuch-redux"
run_benchmark "C" "fasta"
run_benchmark "C" "k-nucleotide"
run_benchmark "C" "mandelbrot"
# run_benchmark "C" "matrix-multiplication" # Not Implemented
run_benchmark "C" "n-body"
run_benchmark "C" "pidigits"
# run_benchmark "C" "polynomial-evaluation" # Not Implemented
run_benchmark "C" "regex-redux"
run_benchmark "C" "reverse-complement"
run_benchmark "C" "spectral-norm"

run_benchmark "C#" "binary-trees"
run_benchmark "C#" "chameneos-redux"
# run_benchmark "C#" "division-loop" # Not Implemented
run_benchmark "C#" "fannkuch-redux"
run_benchmark "C#" "fasta"
run_benchmark "C#" "k-nucleotide"
run_benchmark "C#" "mandelbrot"
# run_benchmark "C#" "matrix-multiplication" # Not Implemented
# run_benchmark "C#" "matrix-multiplication-unsafe" # Not Implemented
run_benchmark "C#" "n-body"
run_benchmark "C#" "pidigits"
# run_benchmark "C#" "polynomial-evaluation" # Not Implemented
run_benchmark "C#" "regex-redux"
run_benchmark "C#" "reverse-complement"
run_benchmark "C#" "spectral-norm"
# run_benchmark "C#" "ThreadRing" # Not Relevant

run_benchmark "C++" "binary-trees"
run_benchmark "C++" "chameneos-redux"
# run_benchmark "C++" "division-loop" # Not Implemented
run_benchmark "C++" "fannkuch-redux"
run_benchmark "C++" "fasta"
run_benchmark "C++" "k-nucleotide"
run_benchmark "C++" "mandelbrot"
# run_benchmark "C++" "matrix-multiplication" # Not Implemented
run_benchmark "C++" "n-body"
run_benchmark "C++" "pidigits"
# run_benchmark "C++" "polynomial-evaluation" # Not Implemented
run_benchmark "C++" "regex-redux"
run_benchmark "C++" "reverse-complement"
run_benchmark "C++" "spectral-norm"

run_benchmark "Java" "binary-trees"
# run_benchmark "Java" "division-loop" # Not Implemented
run_benchmark "Java" "fannkuch-redux"
run_benchmark "Java" "fasta"
run_benchmark "Java" "k-nucleotide"
run_benchmark "Java" "mandelbrot"
# run_benchmark "Java" "matrix-multiplication" # Not Implemented
run_benchmark "Java" "n-body"
# run_benchmark "Java" "polynomial-evaluation" # Not Implemented
run_benchmark "Java" "regex-redux"
# run_benchmark "Java" "reverse-complement" # Not Working
run_benchmark "Java" "spectral-norm"

# run_benchmark "JavaScript" "binary-trees"
# run_benchmark "JavaScript" "fannkuch-redux"
# run_benchmark "JavaScript" "fasta"
# # run_benchmark "JavaScript" "k-nucleotide" # Not Working
# run_benchmark "JavaScript" "mandelbrot"
# run_benchmark "JavaScript" "n-body"
# run_benchmark "JavaScript" "regex-redux"
# run_benchmark "JavaScript" "reverse-complement"
# run_benchmark "JavaScript" "spectral-norm"

# run_benchmark "Python" "binary-trees"
# run_benchmark "Python" "fannkuch-redux"
# run_benchmark "Python" "fasta"
# run_benchmark "Python" "k-nucleotide"
# run_benchmark "Python" "mandelbrot"
# run_benchmark "Python" "n-body"
# run_benchmark "Python" "regex-redux"
# run_benchmark "Python" "reverse-complement"
# run_benchmark "Python" "spectral-norm"

run_benchmark "Rust" "binary-trees"
run_benchmark "Rust" "fannkuch-redux"
run_benchmark "Rust" "fasta"
run_benchmark "Rust" "k-nucleotide"
run_benchmark "Rust" "mandelbrot"
run_benchmark "Rust" "n-body"
run_benchmark "Rust" "pidigits"
run_benchmark "Rust" "regex-redux"
run_benchmark "Rust" "reverse-complement"
run_benchmark "Rust" "spectral-norm"
