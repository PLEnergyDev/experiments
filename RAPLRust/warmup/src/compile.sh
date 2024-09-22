# multiplier to get values in joules 6.103515625e-05

compile_benchmark() {
  local language="$1"
  local algorithm="$2"

  cd "./$language/$algorithm"
  make clean || { echo "[ERROR] Failed to clean"; exit 1; }
  make || { echo "[ERROR] Failed to measure"; exit 1; }
  sleep 1s
  cd "../.."
}

compile_benchmark "C" "binary-trees"
compile_benchmark "C" "chameneos-redux"
compile_benchmark "C" "division-loop"
compile_benchmark "C" "fannkuch-redux"
compile_benchmark "C" "fasta"
compile_benchmark "C" "k-nucleotide"
compile_benchmark "C" "mandelbrot"
compile_benchmark "C" "matrix-multiplication"
compile_benchmark "C" "n-body"
compile_benchmark "C" "pidigits"
compile_benchmark "C" "polynomial-evaluation"
compile_benchmark "C" "regex-redux"
compile_benchmark "C" "reverse-complement"
compile_benchmark "C" "spectral-norm"

compile_benchmark "C#" "binary-trees"
compile_benchmark "C#" "chameneos-redux"
compile_benchmark "C#" "division-loop"
compile_benchmark "C#" "fannkuch-redux"
compile_benchmark "C#" "fasta"
compile_benchmark "C#" "k-nucleotide"
compile_benchmark "C#" "mandelbrot"
compile_benchmark "C#" "matrix-multiplication"
compile_benchmark "C#" "matrix-multiplication-unsafe"
compile_benchmark "C#" "n-body"
compile_benchmark "C#" "pidigits"
compile_benchmark "C#" "polynomial-evaluation"
compile_benchmark "C#" "regex-redux"
compile_benchmark "C#" "reverse-complement"
compile_benchmark "C#" "spectral-norm"
# compile_benchmark "C#" "ThreadRing" # Not Relevant

compile_benchmark "C++" "binary-trees"
compile_benchmark "C++" "chameneos-redux"
# compile_benchmark "C++" "division-loop" # Not Implemented
compile_benchmark "C++" "fannkuch-redux"
# compile_benchmark "C++" "fasta"
compile_benchmark "C++" "k-nucleotide"
compile_benchmark "C++" "mandelbrot"
# compile_benchmark "C++" "matrix-multiplication" # Not Implemented
compile_benchmark "C++" "n-body"
compile_benchmark "C++" "pidigits"
# compile_benchmark "C++" "polynomial-evaluation" # Not Implemented
compile_benchmark "C++" "regex-redux"
compile_benchmark "C++" "reverse-complement"
compile_benchmark "C++" "spectral-norm"

compile_benchmark "Java" "binary-trees"
compile_benchmark "Java" "division-loop"
compile_benchmark "Java" "fannkuch-redux"
compile_benchmark "Java" "fasta"
compile_benchmark "Java" "k-nucleotide"
compile_benchmark "Java" "mandelbrot"
compile_benchmark "Java" "matrix-multiplication"
compile_benchmark "Java" "n-body"
compile_benchmark "Java" "polynomial-evaluation"
compile_benchmark "Java" "regex-redux"
# compile_benchmark "Java" "reverse-complement" # Not Working
compile_benchmark "Java" "spectral-norm"

# compile_benchmark "JavaScript" "binary-trees"
# compile_benchmark "JavaScript" "fannkuch-redux"
# compile_benchmark "JavaScript" "fasta"
# # compile_benchmark "JavaScript" "k-nucleotide" # Not Working
# compile_benchmark "JavaScript" "mandelbrot"
# compile_benchmark "JavaScript" "n-body"
# compile_benchmark "JavaScript" "regex-redux"
# compile_benchmark "JavaScript" "reverse-complement"
# compile_benchmark "JavaScript" "spectral-norm"

# compile_benchmark "Python" "binary-trees"
# compile_benchmark "Python" "fannkuch-redux"
# compile_benchmark "Python" "fasta"
# compile_benchmark "Python" "k-nucleotide"
# compile_benchmark "Python" "mandelbrot"
# compile_benchmark "Python" "n-body"
# compile_benchmark "Python" "regex-redux"
# compile_benchmark "Python" "reverse-complement"
# compile_benchmark "Python" "spectral-norm"

compile_benchmark "Rust" "binary-trees"
compile_benchmark "Rust" "fannkuch-redux"
compile_benchmark "Rust" "fasta"
compile_benchmark "Rust" "k-nucleotide"
compile_benchmark "Rust" "mandelbrot"
compile_benchmark "Rust" "n-body"
compile_benchmark "Rust" "pidigits"
compile_benchmark "Rust" "regex-redux"
compile_benchmark "Rust" "reverse-complement"
compile_benchmark "Rust" "spectral-norm"
