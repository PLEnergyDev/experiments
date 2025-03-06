#!/bin/bash

REPORT_SCRIPTS_DIR="$LIB_DIR/python-scripts"
REPORT_DIR="."
REPORT_CONF=("no-warmup" "warmup")
REPORT_LANG=()
REPORT_BENCH=()
REPORT_SKIP=0
REPORT_AVERAGE=false
REPORT_NORMALIZE=false
REPORT_VIOLIN=false
REPORT_INTERACTIVE=false
REPORT_PYTHON="python"
REPORT_PIP="pip"


report_description() {
    echo "Compiles measurement results into nice reports"
}

report_help() {
    cat << HELP
Usage:
    $TOOL_NAME report [DIR] [OPTIONS]

DIR:
    The base directory path where measurements are located. Default current dir

Options:
    -l, --lang <languages>   Comma-separated list of languages. Default takes all dirs under DIR
    -b, --bench <benchmarks> Comma-separated list of benchmarks. Default takes all dirs under LANGUAGES
    -s, --skip <count>       Skips the first <count> results for each measurement before reporting
    -a, --average            Produce a table with averaged results
    -o, --normalize          Produce a 
    -v, --violin             Produce violin and box-plots for each measurement
    -i, --interactive        Produces interactive html plots for each measurement
    -h, --help               Show this help message

HELP
}

report_ensure_dependencies() {
    if command -v python3 &>/dev/null; then
        REPORT_PYTHON="python3"
    elif command -v python &>/dev/null; then
        REPORT_PYTHON="python"
    else
        error "\"python\" is not installed."
    fi

    if command -v pip3 &>/dev/null; then
        REPORT_PIP="pip3"
    elif command -v pip &>/dev/null; then
        REPORT_PIP="pip"
    else
        error "\"pip\" is not installed. Please install python3-pip package."
    fi

    local requirements_file="$REPORT_SCRIPTS_DIR/requirements.txt"
    if [[ ! -f "$requirements_file" ]]; then
        error "requirements.txt file not found: $requirements_file"
    fi

    local all_installed=true
    while IFS= read -r package || [ -n "$package" ]; do
        if ! pip show "$package" > /dev/null 2>&1; then
            all_installed=false
        fi
    done < "$requirements_file"

    if ! $all_installed; then
        info "Missing Python dependencies detected."
        read -p "Would you like to install them now? [y/N] " -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo $PIP install -r "$requirements_file" || error "Failed to install Python dependencies."
        else
            error "Required Python packages must be installed to continue."
        fi
    fi
}

report_main() {
    local options=$(getopt -o l:b:s:anvi --long lang:,bench:,skip:,averaged,normalized,violin,interactive -- "$@")
    eval set -- "$options"

    while true; do
        case "$1" in
            -l|--lang)
                IFS="," read -r -a REPORT_LANG <<< "$2"
                shift
                ;;
            -b|--bench)
                IFS="," read -r -a REPORT_BENCH <<< "$2"
                shift
                ;;
            -s|--skip)
                REPORT_SKIP="$2"
                shift
                ;;
            -a|--average)
                REPORT_AVERAGE=true
                ;;
            -n|--normalize)
                REPORT_NORMALIZE=true
                ;;
            -v|--violin)
                REPORT_VIOLIN=true
                ;;
            -i|--interactive)
                REPORT_INTERACTIVE=true
                ;;
            --)
                shift
                break
                ;;
            *)
                error "\"$1\" is not a known option. See \"$TOOL_NAME report --help\"."
                ;;
        esac
        shift
    done

    if [[ ! -z "$1" ]]; then
        REPORT_DIR="$1"
    fi

    if [[ ! -d "$REPORT_DIR" ]]; then
        error "Specified base directory $REPORT_DIR does not exist."
    fi

    report_ensure_dependencies

    if [[ ${#REPORT_LANG[@]} -eq 0 && ${#REPORT_BENCH[@]} -eq 0 ]]; then
        rapl_csv=$(find . -maxdepth 1 -name "Intel_*.csv" -o -name "AMD_*.csv")
        if [[ ! -z "$rapl_csv" && -f "perf.txt" ]]; then

            $REPORT_PYTHON "$REPORT_SCRIPTS_DIR/compile.py" "$rapl_csv" || error "Failed to compile rapl measurements."

            if $REPORT_AVERAGE; then
                $REPORT_PYTHON "$REPORT_SCRIPTS_DIR/average.py" "$rapl_csv" -s "$REPORT_SKIP" || error "Failed to average rapl measurements."
            fi

            if $REPORT_VIOLIN; then
                $REPORT_PYTHON "$REPORT_SCRIPTS_DIR/violin.py" "$rapl_csv" -s "$REPORT_SKIP" || error "Failed to create violin plot."
            fi

            exit 0
        fi
    fi

    if [[ ${#REPORT_LANG[@]} -eq 0 ]]; then
        REPORT_LANG=($(find "$REPORT_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort))
        if [[ ${#REPORT_LANG[@]} -eq 0 ]]; then
            error "No language dirs found in \"$REPORT_DIR\"."
        fi
    fi

    if [[ ${#REPORT_BENCH[@]} -eq 0 ]]; then
        declare -A BENCHMARK_SET

        for lang in "${REPORT_LANG[@]}"; do
            if [[ -d "$REPORT_DIR/$lang" ]]; then
                for benchmark in $(find "$REPORT_DIR/$lang" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort); do
                    BENCHMARK_SET["$benchmark"]=1
                done
            fi
        done

        REPORT_BENCH=("${!BENCHMARK_SET[@]}")

        if [[ ${#REPORT_BENCH[@]} -eq 0 ]]; then
            error "No benchmarks found under any language directory."
        fi
    fi

    rm -f "rapl.csv"
    rm -f "averaged.csv"
    rm -f "normalized.csv"

    local rapl_csvs=()
    for lang in "${REPORT_LANG[@]}"; do
        rapl_csvs=()
        for bench in "${REPORT_BENCH[@]}"; do
            bench_dir="$lang/$bench"
            if [[ ! -d "$bench_dir" ]]; then
                continue
            fi
            rapl_csv=$(find "$bench_dir" -maxdepth 1 -name "Intel_*.csv" -o -name "AMD_*.csv")
            rapl_csvs+=("$rapl_csv")

            if $REPORT_VIOLIN; then
                $REPORT_PYTHON "$REPORT_SCRIPTS_DIR/violin.py" "$rapl_csv" -s "$REPORT_SKIP" || error "Failed to create violin plot."
                mkdir -p "plots/$lang/$bench/violins"
                mv violin.png "plots/$lang/$bench/violins"
            fi
        done

        $REPORT_PYTHON "$REPORT_SCRIPTS_DIR/compile.py" "${rapl_csvs[@]}" || error "Failed to compile rapl measurements."

        if $REPORT_AVERAGE; then
            $REPORT_PYTHON "$REPORT_SCRIPTS_DIR/average.py" "${rapl_csvs[@]}" -s "$REPORT_SKIP" -l "$lang" || error "Failed to average rapl measurements."
        fi
    done
}
