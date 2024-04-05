move_result() {
  local language="$1"
  local algorithm="$2"
  local args="${@:3}"
  latest_result=$(find . -maxdepth 1 -name '*.csv' -printf '%T+ %p\n' | sort -r | head -n 1 | cut -d' ' -f2-)
  timestamp=$(date +%s)
  results_dir="../results"
  joined_args=""

  if [[ ! -d "${results_dir}/${language}/${algorithm}" ]]; then
    mkdir -p "${results_dir}/${language}/${algorithm}"
  fi

  for arg in "${@:3}"; do
    if [[ -z "$joined_args" ]]; then
      joined_args="$arg"
    else
      joined_args="${joined_args}_$arg"
    fi
  done

  mv "$latest_result" "${results_dir}/${language}/${algorithm}/${language}_${algorithm}_${joined_args}_${timestamp}.csv"
}

run_benchmark() {
  local language="$1"
  local algorithm="$2"
  local args=("${@:3}")

  local start_time=$(date)
  echo "--- Starting $language $algorithm --- time: $start_time"

  java --enable-native-access=ALL-UNNAMED --enable-preview --source 21 -server "$language/$algorithm/main.java" "${args[@]}"
  sleep 1s

  move_result "$language" "$algorithm" "${args[@]}"

  local end_time=$(date)
  echo "--- Finished $language $algorithm --- time: $end_time"
  echo
}

run_benchmark "Java" "NBody"                      2 50000000

# run_benchmark "Java" "FannkuchRedux"              2 12

run_benchmark "Java" "Mandelbrot"                 2 16000

# run_benchmark "Java" "Pidigits"                   2 10000

run_benchmark "Java" "SpectralNorm"               2 10000

run_benchmark "Java" "PolynomialEvaluation"       2 10000

run_benchmark "Java" "DivisionLoop"               2 22

run_benchmark "Java" "MatrixMultiplication"       2 80 80


# multiplier to get values in joules 6.103515625e-05