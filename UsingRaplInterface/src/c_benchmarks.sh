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

  # dotnet build "$language/$algorithm" --configuration Release
  gcc "$language/$algorithm/main.c" -O3 -fomit-frame-pointer -march=ivybridge -mno-fma -fno-finite-math-only -fopenmp -o "$language/$algorithm/main" -L"./rapl-interface/target/release" -lrapl_lib -lgmp -lm -Wl,-rpath="./rapl-interface/target/release"

  local start_time=$(date)
  echo "--- Starting $language $algorithm --- time: $start_time"

  # "./$language/$algorithm/bin/Release/net8.0/$algorithm" "${args[@]}"
  "./$language/$algorithm/main" "${args[@]}"
  sleep 1s

  move_result "$language" "$algorithm" "${args[@]}"

  local end_time=$(date)
  echo "--- Finished $language $algorithm --- time: $end_time"
  echo
}

run_benchmark "C" "NBody"                500 50000000

run_benchmark "C" "FannkuchRedux"        500 12

run_benchmark "C" "Mandelbrot"           500 16000

run_benchmark "C" "Pidigits"             500 10000

run_benchmark "C" "SpectralNorm"         500 10000

run_benchmark "C" "PolynomialEvaluation" 500 10000

run_benchmark "C" "DivisionLoop"         500 22

run_benchmark "C" "MatrixMultiplication" 500 80 80

# multiplier to get values in joules 6.103515625e-05