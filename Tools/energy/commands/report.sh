#!/bin/bash

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
Attention!
    This command is quite heavy so expect it to hang.

Usage:
    $NAME report [DIR] [OPTIONS]

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

report_dependencies() {
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

    local requirements_file="$SCRIPTS_DIR/requirements.txt"
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
        error "Missing Python dependencies detected. Please install them via your package manager."
    fi
}

report_main() {
    local options=$(getopt -o l:b:s:anvi --long lang:,bench:,skip:,average,normalized,violin,interactive -- "$@")
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
                error "\"$1\" is not a known option. See \"$NAME report --help\"."
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

    report_dependencies

    if [[ ${#REPORT_LANG[@]} -eq 0 && ${#REPORT_BENCH[@]} -eq 0 ]]; then
        local intel_csv=( $(find . -maxdepth 1 -type f -name "Intel_*.csv") )
        local amd_csv=( $(find . -maxdepth 1 -type f -name "AMD_*.csv") )
        local rapl_csv=""
        if [[ ${#intel_csv[@]} -gt 0 || ${#amd_csv[@]} -gt 0 ]]; then
            if [[ ${#intel_csv[@]} -gt 0 && ${#amd_csv[@]} -gt 0 ]]; then
                error "Can't have both Intel and AMD measurements in current directory."
            fi

            if [[ ${#intel_csv[@]} -eq 1 ]]; then
                rapl_csv="${intel_csv[0]}"
            elif [[ ${#amd_csv[@]} -eq 1 ]]; then
                rapl_csv="${amd_csv[0]}"
            else
                error "Rapl measurement doesn't exist in current directory."
            fi

            if [[ ! -f perf.txt ]]; then
                error "Perf measurement doesn't exist in current directory."
            fi

            rm -f rapl.csv
            $REPORT_PYTHON "$SCRIPTS_DIR/compile.py" "$rapl_csv" || error "Failed to compile rapl measurements."
            if $REPORT_AVERAGE; then
                rm -f "averaged_perf.csv" "averaged_rapl.csv"
                $REPORT_PYTHON "$SCRIPTS_DIR/average.py" --rapl "$rapl_csv" --perf "perf.txt" --skip "$REPORT_SKIP" || error "Failed to average rapl measurements."
            fi
            if $REPORT_VIOLIN; then
                $REPORT_PYTHON "$SCRIPTS_DIR/violin.py" "$rapl_csv" --skip "$REPORT_SKIP" || error "Failed to create violin plot."
            fi
            if $REPORT_INTERACTIVE; then
                $REPORT_PYTHON "$SCRIPTS_DIR/interactive.py" "$rapl_csv" perf.txt --skip "$REPORT_SKIP" || error "Failed to create interactive plot."
            fi

            exit 0
        fi
    fi

    if [[ ${#REPORT_LANG[@]} -eq 0 ]]; then
        REPORT_LANG=($(find "$REPORT_DIR" -mindepth 1 -maxdepth 1 -type d ! -name "plots" -exec basename {} \; | sort))
        if [[ ${#REPORT_LANG[@]} -eq 0 ]]; then
            error "No language dirs found in \"$REPORT_DIR\"."
        fi
    fi

    if [[ ${#REPORT_BENCH[@]} -eq 0 ]]; then
        declare -A BENCHMARK_SET
        for lang in "${REPORT_LANG[@]}"; do
            if [[ -d "$REPORT_DIR/$lang" ]]; then
                for benchmark in $(find "$REPORT_DIR/$lang" -mindepth 1 -maxdepth 1 -type d ! -name "plots" -exec basename {} \; | sort); do
                    BENCHMARK_SET["$benchmark"]=1
                done
            fi
        done
        REPORT_BENCH=("${!BENCHMARK_SET[@]}")
        if [[ ${#REPORT_BENCH[@]} -eq 0 ]]; then
            error "No benchmarks found under any language directory."
        fi
    fi

    rm -f "$REPORT_DIR/rapl.csv"

    if $REPORT_AVERAGE; then
        rm -f "$REPORT_DIR/averaged_rapl.csv"
        rm -f "$REPORT_DIR/averaged_perf.csv"
    fi

    if $REPORT_VIOLIN; then
        rm -rf "$REPORT_DIR/plots/violins"
    fi

    if $REPORT_INTERACTIVE; then
        rm -rf "$REPORT_DIR/plots/interactive"
    fi

    for lang in "${REPORT_LANG[@]}"; do
        local rapl_csvs=()
        local perf_txts=()
        for bench in "${REPORT_BENCH[@]}"; do
            bench_dir="$REPORT_DIR/$lang/$bench"
            if [[ ! -d "$bench_dir" ]]; then
                continue
            fi

            while IFS= read -r file; do
                rapl_csvs+=("$file")
            done < <(find "$bench_dir" -maxdepth 1 -type f \( -name "Intel_*.csv" -o -name "AMD_*.csv" \))

            intel_found=false
            amd_found=false
            for csv in "${rapl_csvs[@]}"; do
                if [[ "$csv" == *"Intel_"* ]]; then
                    intel_found=true
                elif [[ "$csv" == *"AMD_"* ]]; then
                    amd_found=true
                fi
            done
            if $intel_found && $amd_found; then
                error "Can't have both Intel and AMD measurement files in $bench_dir for language $lang."
            fi

            perf_txt="$bench_dir/perf.txt"
            if [[ -f "$perf_txt" ]]; then
                perf_txts+=("$perf_txt")
            fi

            if $REPORT_VIOLIN; then
                local violins_dir="$REPORT_DIR/plots/violins/$lang/$bench"
                for csv in "${rapl_csvs[@]}"; do
                    if [[ ! -f "$csv" ]]; then
                        warning "Missing required rapl measurement for \"$lang\" \"$bench\"."
                        continue
                    fi
                    $REPORT_PYTHON "$SCRIPTS_DIR/violin.py" "$csv" \
                        --skip "$REPORT_SKIP" \
                        || error "Failed to create violin plot."

                    mkdir -p "$violins_dir"
                    mv violin.png "$violins_dir"
                done
            fi

            if $REPORT_INTERACTIVE; then
                local interactive_dir="$REPORT_DIR/plots/interactive/$lang/$bench"
                for csv in "${rapl_csvs[@]}"; do
                    if [[ ! -f "$bench_dir/perf.txt" ]]; then
                        warning "Missing required \"perf.txt\" for \"$lang\" \"$bench\"."
                        continue
                    fi
                    $REPORT_PYTHON "$SCRIPTS_DIR/interactive.py" \
                        "$csv" "$bench_dir/perf.txt" \
                        --skip "$REPORT_SKIP" \
                        || error "Failed to create interactive plot."
                    mkdir -p "$interactive_dir"
                    mv interactive.html "$interactive_dir"
                done
            fi
        done

        $REPORT_PYTHON "$SCRIPTS_DIR/compile.py" "${rapl_csvs[@]}" || error "Failed to compile rapl measurements."

        if $REPORT_AVERAGE; then
            $REPORT_PYTHON "$SCRIPTS_DIR/average.py" \
                --rapl "${rapl_csvs[@]}" \
                --perf "${perf_txts[@]}" \
                --skip "$REPORT_SKIP" \
                --language "$lang" \
                || error "Failed to average measurements."
        fi
    done

    if [[ $REPORT_DIR != "." ]]; then
        mv rapl.csv "$REPORT_DIR"

        if $REPORT_AVERAGE; then
            mv "averaged_rapl.csv" "averaged_perf.csv" "$REPORT_DIR"
        fi
    fi
}
