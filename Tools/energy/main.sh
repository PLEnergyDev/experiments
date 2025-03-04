#!/bin/bash

LIBDIR=/usr/local/lib/energy

source "$LIBDIR/utils.sh"

###################################### MEASURE #####################################
MEASURE_COUNT=45
MEASURE_FREQ=500
MEASURE_DIR="."
MEASURE_SETUP="production"
MEASURE_CONF=("no-warmup" "warmup")
MEASURE_LANG=()
MEASURE_BENCH=()
MEASURE_PRIORITY=
MEASURE_SLEEP=60
MEASURE_STOP=false

intro_measure() {
    clear; cat << HELP
========== Measurement Setup ==================
Configuration File    | ${MEASURE_CONF[*]}
OS Environment        | $MEASURE_SETUP
Repetitions           | $MEASURE_COUNT
Measurement Freq      | $MEASURE_FREQ ms
Measurement Sleep     | $MEASURE_SLEEP s
Stop After Fail       | $MEASURE_STOP

========== CPU Scaling & Performance ==========
Scaling Driver        | $MEASURE_DRIVER ($MEASURE_DRIVER_STATUS)
Scaling Governor      | $MEASURE_GOVERNOR
Frequency Range       | $MEASURE_MIN_FREQ MHz - $MEASURE_MAX_FREQ MHz
Boost State           | $MEASURE_TURBO
Process Priority      | ${MEASURE_PRIORITY:-default}
ASLR                  | $MEASURE_ASLR

========== Running Configuration ==============
Base Directory        | $MEASURE_DIR
Language Directories  | ${MEASURE_LANG[*]}
Benchmark Directories | ${MEASURE_BENCH[*]}
HELP
}

help_measure() {
    cat << HELP

Usage:
    $SCRIPT_NAME measure DIR [OPTIONS]

DIR:
    The base directory path to start the measurements in.

Options:
    -n, --no-warmup          Only measures using 'no-warmup' config. 
    -w, --warmup             Only measures using 'warmup' config.
    -l, --lang  LANGUAGES    Comma-separated list of languages. Default takes all dirs under DIR.
    -b, --bench BENCHMARKS   Comma-separated list of benchmarks. Default takes all dirs under LANGUAGES.
    --lab                    OS will enter the 'lab' environment before measuring. Default production.
    --prod                   OS will enter the 'production' environment before measuring. Default production.
    --light                  OS will enter the 'lightweight' environment before measuring. Default production.
    -s, --sleep SECS         Number of seconds to sleep between each successful measurement. Default 60.
    --stop                   Stop after a failed measurement.
    -c, --count COUNT        Number of measurement repetitions. Default 45.
    -f, --freq  MS           perf measurement frequency in milliseconds. Default 500.

HELP
}

ensure_measure_dependencies() {
    if ! command -v modprobe &>/dev/null; then
        error "'modprobe' is not installed. Please install the 'kmod' package and try again."
    fi

    if ! command -v cpupower &>/dev/null; then
        error "'cpupower' not found. Install 'linux-tools' or equivalent package."
    fi

    if ! modprobe msr; then
        error "Failed to load 'msr' kernel module. Ensure it is available and try again."
    fi
}

build_measure_command() {
    perf_command="perf stat --all-cpus -I $MEASURE_FREQ \
        --append --output perf.txt \
        -e cache-misses,branch-misses,LLC-loads-misses,msr/cpu_thermal_margin/,cpu-clock,cycles \
        -e cstate_core/c3-residency/,cstate_core/c6-residency/,cstate_core/c7-residency/"

    case "$1" in
        no-warmup)
            command="$MEASURE_PRIORITY $perf_command bash -c 'for i in \$(seq 1 $MEASURE_COUNT); do make measure; done'"
            ;;
        warmup)
            command="$MEASURE_PRIORITY $perf_command env RAPL_ITERATIONS=$MEASURE_COUNT make measure"
            ;;
        *)
            command=""
            ;;
    esac

    echo "$command"
}

handle_measure() {
    if [[ ! -z "$1" ]]; then
        MEASURE_DIR="$1"
    fi

    if [[ ! -d "$MEASURE_DIR" ]]; then
        error "Specified base directory $MEASURE_DIR does not exist."
    fi

    ensure_measure_dependencies

    case "$MEASURE_SETUP" in
        production)
            info "Sourcing production environment.\n"
            source "$LIBDIR/production.sh"
            ;;
        lab)
            info "Sourcing lab environment.\n"
            source "$LIBDIR/lab.sh"
            ;;
        lightweight)
            info "Sourcing lightweight environment.\n"
            source "$LIBDIR/lightweight.sh"
            ;;
    esac

    set_measure_variables

    MEASURE_CONF=($(shuf -e "${MEASURE_CONF[@]}"))

    if [[ ${#MEASURE_LANG[@]} -eq 0 && ${#MEASURE_BENCH[@]} -eq 0 ]]; then
        if [[ -f "Makefile" || -f "makefile" || -f "GNUmakefile" ]]; then
            intro_measure

            for conf in "${MEASURE_CONF[@]}"; do
                info "Measuring in current directory with $conf.\n"

                command=$(build_measure_command "$conf")

                if ! eval "$command"; then
                    warning "Failed to measure in current directory with $conf."
                    if $MEASURE_STOP; then
                        exit 1
                    fi
                fi
            done
            exit 0
        fi
    fi

    if [[ ${#MEASURE_LANG[@]} -eq 0 ]]; then
        MEASURE_LANG=($(find "$MEASURE_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort))
        if [[ ${#MEASURE_LANG[@]} -eq 0 ]]; then
            error "No language dirs found in '$MEASURE_DIR'."
        fi
    fi

    if [[ ${#MEASURE_BENCH[@]} -eq 0 ]]; then
        declare -A BENCHMARK_SET

        for lang in "${MEASURE_LANG[@]}"; do
            if [[ -d "$MEASURE_DIR/$lang" ]]; then
                for benchmark in $(find "$MEASURE_DIR/$lang" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort); do
                    BENCHMARK_SET["$benchmark"]=1
                done
            fi
        done

        MEASURE_BENCH=("${!BENCHMARK_SET[@]}")

        if [[ ${#MEASURE_BENCH[@]} -eq 0 ]]; then
            error "No benchmarks found under any language directory."
        fi
    fi

    MEASURE_LANG=($(shuf -e "${MEASURE_LANG[@]}"))
    MEASURE_BENCH=($(shuf -e "${MEASURE_BENCH[@]}"))

    intro_measure

    info "Starting measurements in $MEASURE_SLEEP s."
    sleep $MEASURE_SLEEP

    pushd "$MEASURE_DIR" >/dev/null

    for conf in "${MEASURE_CONF[@]}"; do
        for lang in "${MEASURE_LANG[@]}"; do
            for bench in "${MEASURE_BENCH[@]}"; do
                bench_dir="$lang/$bench"

                if [[ ! -d "$bench_dir" ]]; then
                    continue
                fi

                pushd "$bench_dir" >/dev/null

                command=$(build_measure_command "$conf")

                info "Measuring $lang $bench with $conf.\n"
                if eval "$command"; then
                    measurement=$(find . -maxdepth 1 -name '*.csv' -printf '%T+ %p\n' | sort -r | head -n 1 | cut -d' ' -f2-)
                    if [[ -f "$measurement" ]]; then
                        info "Finished measuring for $lang $bench with $conf."
                        results_dir="../../../results/$conf/$lang/$bench"
                        mkdir -p "$results_dir"
                        mv "$measurement" "perf.txt" "$results_dir"
                        info "Sleeping for $MEASURE_SLEEP s."
                        sleep "$MEASURE_SLEEP"
                    else
                        warning "No measurement generated for $lang $bench with $conf."
                        if $MEASURE_STOP; then
                            exit 1
                        fi
                    fi
                else
                    warning "Failed to measure for $lang $bench with $conf."
                    if $MEASURE_STOP; then
                        exit 1
                    fi
                fi

                popd >/dev/null
            done
        done
    done

    popd >/dev/null
}
###################################### MEASURE #####################################

###################################### REPORT ######################################
###################################### REPORT ######################################

###################################### EXPORT ######################################
###################################### EXPORT ######################################

help_energy() {
    cat << HELP

Usage:
    $SCRIPT_NAME {--version|--help} [COMMAND] [OPTIONS]

Commands:
    measure   Use 'rapl-interface' and 'perf' command to measure programs
    report    Compile raw measurements into useful reports
    export    Export program assembly

HELP
}


help_command() {
    if [[ $# -eq 0 ]]; then
        cat << HELP

Usage:
    $SCRIPT_NAME help {measure|report|export}

HELP
        exit 1
    fi

    case "$1" in
        measure)
            help_measure
            ;;
        report)
            help_report
            ;;
        export)
            help_export
            ;;
        *)
            error "No help entry for '$1'."
            ;;
    esac
}

parse_commands() {
    options=$(getopt -o vhnws:l:b:c:f: --long version,help,no-warmup,warmup,lang:,bench:,count:,freq:,sleep:,lab,prod,light,stop -- "$@")
    eval set -- "$options"

    while true; do
        case "$1" in
            -v|--version)
                echo "energy 1.0"
                exit 0
                ;;
            -h|--help)
                help_energy
                exit 0
                ;;
            -n|--no-warmup)
                MEASURE_CONF=("no-warmup")
                shift
                ;;
            -w|--warmup)
                MEASURE_CONF=("warmup")
                shift
                ;;
            -l|--lang)
                IFS="," read -r -a MEASURE_LANG <<< "$2"
                shift 2
                ;;
            -b|--bench)
                IFS="," read -r -a MEASURE_BENCH <<< "$2"
                shift 2
                ;;
            -c|--count)
                MEASURE_COUNT="$2"
                shift 2
                ;;
            -s|--sleep)
                MEASURE_SLEEP="$2"
                shift 2
                ;;
            --stop)
                MEASURE_STOP=true
                shift
                ;;
            --lab)
                MEASURE_SETUP="lab"
                shift
                ;;
            --prod)
                MEASURE_SETUP="production"
                shift
                ;;
            --light)
                MEASURE_SETUP="lightweight"
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                error "'$1' is not a known $SCRIPT_NAME option. See '$SCRIPT_NAME --help'."
                ;;
        esac
    done

    if [[ -z "$1" ]]; then
        help_energy
        exit 1
    fi

    case "$1" in
        measure)
            shift
            handle_measure "$@"
            ;;
        report)
            shift
            handle_report "$@"
            ;;
        export)
            shift
            handle_export "$@"
            ;;
        help)
            shift
            help_command "$@"
            ;;
        *)
            error "'$1' is not a known $SCRIPT_NAME command. See '$SCRIPT_NAME --help'."
            ;;
    esac
}

parse_commands "$@"
