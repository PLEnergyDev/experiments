#!/bin/bash

MEASURE_COUNT=45
MEASURE_FREQ=500
MEASURE_DIR="."
MEASURE_SETUP="production"
MEASURE_CONF=("no-warmup" "warmup")
MEASURE_LANG=()
MEASURE_BENCH=()
MEASURE_PRIORITY=""
MEASURE_SLEEP=60
MEASURE_STOP=false
MEASURE_DRIVER=""
MEASURE_DRIVER_STATUS=""
MEASURE_GOVERNOR=""
MEASURE_MIN_FREQ=""
MEASURE_MAX_FREQ=""
MEASURE_TURBO=""
MEASURE_ASLR=""

measure_description() {
    echo "Use \"perf\" and \"rapl_interface\" to measure programs"
}

measure_help() {
    cat << HELP
Usage:
    $NAME measure [DIR] [OPTIONS]

DIR:
    The base directory path to start the measurements in. Default current dir

Options:
    -n, --no-warmup          Only measures using "no-warmup" config
    -w, --warmup             Only measures using "warmup" config
    -l, --lang  <languages>  Comma-separated list of languages. Default takes all dirs under DIR
    -b, --bench <benchmarks> Comma-separated list of benchmarks. Default takes all dirs under LANGUAGES
    -s, --sleep <seconds>    Number of seconds to sleep between each successful measurement. Default 60
        --stop               Stop after a failed measurement
    -c, --count <count>      Number of measurement repetitions. Default 45
    -f, --freq  <freq>       perf measurement frequency in milliseconds. Default 500
        --setup <name>       OS will enter the specified setup before measuring. Default production
    -h, --help               Show this help message

HELP
}

measure_setup() {
    if [[ ! -f "$SETUPS_DIR/${MEASURE_SETUP}.sh" ]]; then
        error "Unknown setup '$MEASURE_SETUP'"
    fi

    source "$SETUPS_DIR/${MEASURE_SETUP}.sh"
}

measure_splash() {
    MEASURE_DRIVER=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_driver)
    if [[ "$MEASURE_DRIVER" == "amd-pstate-epp" ]]; then
        MEASURE_DRIVER="amd_pstate"
    fi
    MEASURE_DRIVER_STATUS=$(cat /sys/devices/system/cpu/$MEASURE_DRIVER/status 2>/dev/null || echo "N/A")
    MEASURE_GOVERNOR=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor)
    MEASURE_MIN_FREQ=$(( $(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq) / 1000 ))
    MEASURE_MAX_FREQ=$(( $(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq) / 1000 ))
    MEASURE_ASLR=$(cat /proc/sys/kernel/randomize_va_space 2>/dev/null || echo "N/A")

    case "$MEASURE_ASLR" in
        0) MEASURE_ASLR="Disabled (No randomization)" ;;
        1) MEASURE_ASLR="Enabled (Partial randomization)" ;;
        2) MEASURE_ASLR="Fully Enabled (Full randomization)" ;;
        *) MEASURE_ASLR="Unknown" ;;
    esac

    if cpupower frequency-info | grep -q "Active: yes"; then
        MEASURE_TURBO="Enabled"
    else
        MEASURE_TURBO="Disabled"
    fi

    MEASURE_CONF=($(shuf -e "${MEASURE_CONF[@]}"))

    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    NC=$(tput sgr0) 

    clear
    cat << HELP
========== Measurement Setup ==================
Configuration         | ${GREEN}${MEASURE_CONF[*]}${NC}
OS Environment        | ${GREEN}$MEASURE_SETUP${NC}
Iterations            | ${YELLOW}$MEASURE_COUNT${NC}
Measurement Freq      | ${YELLOW}$MEASURE_FREQ${NC} ms
Measurement Sleep     | ${YELLOW}$MEASURE_SLEEP${NC} s
Stop After Fail       | $MEASURE_STOP

========== CPU Scaling & Performance ==========
Scaling Driver        | $MEASURE_DRIVER ($MEASURE_DRIVER_STATUS)
Scaling Governor      | $MEASURE_GOVERNOR
Frequency Range       | $MEASURE_MIN_FREQ MHz - $MEASURE_MAX_FREQ MHz
Boost State           | $MEASURE_TURBO
Process Priority      | ${MEASURE_PRIORITY:-default}
Process Affinity      | ${MEASURE_AFFINITY:-default}
ASLR                  | $MEASURE_ASLR

========== Running Configuration ==============
Base Directory        | $MEASURE_DIR
Language Directories  | ${MEASURE_LANG[*]}
Benchmark Directories | ${MEASURE_BENCH[*]}
HELP
}

measure_dependencies() {
    if ! command -v modprobe &>/dev/null; then
        error "\"modprobe\" is not installed. Please install the \"kmod\" package and try again."
    fi

    if ! command -v cpupower &>/dev/null; then
        error "\"cpupower\" not found. Install \"linux-tools\" or equivalent package."
    fi

    if ! modprobe msr; then
        error "Failed to load \"msr\" kernel module. Ensure it is available and try again."
    fi
}

measure_build_command() {
    local perf_command="perf stat --all-cpus -I $MEASURE_FREQ \
        --append --output perf.txt \
        -e cache-misses,branch-misses,LLC-loads-misses,msr/cpu_thermal_margin/,cpu-clock,cycles \
        -e cstate_core/c3-residency/,cstate_core/c6-residency/,cstate_core/c7-residency/"
    local proc_environment="env LD_LIBRARY_PATH=$LIB_DIR:LD_LIBRARY_PATH $MEASURE_PRIORITY $MEASURE_AFFINITY"
    local measure_command=""

    case "$1" in
        no-warmup)
            measure_command="$proc_environment $perf_command  \
            bash -c 'for i in \$(seq 1 $MEASURE_COUNT); do make measure >> output.txt || exit 1; done'"
            ;;
        warmup)
            measure_command="$proc_environment $perf_command  \
            env RAPL_ITERATIONS=$MEASURE_COUNT make measure >> output.txt"
            ;;
    esac

    echo "$measure_command"
}

measure_verify_command() {
    for _ in $(seq 1 "$MEASURE_COUNT"); do
        cat expected.txt
    done | md5sum > digest
    cat output.txt | md5sum -c digest
    local result=$?
    rm -f digest
    return $result
}

measure_failed_to() {
    if $MEASURE_STOP; then
        error "Failed to $1."
    else
        warning "Failed to $1."
    fi
}

measure_main() {
    if [[ $EUID -ne 0 ]]; then
        error "Measure requires root privileges."
    fi

    local options=$(getopt -o nwl:b:c:s: --long no-warmup,warmup,stop,setup:,lang:,bench:,count:,freq:,sleep: -- "$@")
    eval set -- "$options"

    while true; do
        case "$1" in
            -n|--no-warmup)
                MEASURE_CONF=("no-warmup")
                ;;
            -w|--warmup)
                MEASURE_CONF=("warmup")
                ;;
            -l|--lang)
                IFS="," read -r -a MEASURE_LANG <<< "$2"
                shift
                ;;
            -b|--bench)
                IFS="," read -r -a MEASURE_BENCH <<< "$2"
                shift
                ;;
            -c|--count)
                MEASURE_COUNT="$2"
                shift
                ;;
            -s|--sleep)
                MEASURE_SLEEP="$2"
                shift
                ;;
            --stop)
                MEASURE_STOP=true
                ;;
            --setup)
                read -r MEASURE_SETUP <<< "$2"
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                error "\"$1\" is not a known option. See \"$NAME measure --help\"."
                ;;
        esac
        shift
    done

    if [[ ! -z "$1" ]]; then
        MEASURE_DIR="$1"
    fi

    if [[ ! -d "$MEASURE_DIR" ]]; then
        error "Specified base directory $MEASURE_DIR does not exist."
    fi

    measure_dependencies

    if [[ ${#MEASURE_LANG[@]} -eq 0 && ${#MEASURE_BENCH[@]} -eq 0 ]]; then
        if [[ -f "Makefile" || -f "makefile" || -f "GNUmakefile" ]]; then
            measure_setup
            measure_splash
            for conf in "${MEASURE_CONF[@]}"; do
                info "Measuring in '$MEASURE_DIR' with $conf.\n"

                if ! make clean >/dev/null; then
                    measure_failed_to "clean"; continue
                fi
 
                if ! make all >/dev/null; then
                    measure_failed_to "build"; continue
                fi

                if ! eval $(measure_build_command "$conf"); then
                    rm -f perf.txt output.txt
                    measure_failed_to "measure"; continue
                fi

                local measurement=( $(find . -maxdepth 1 -type f -name "Intel_*.csv" -o -name "AMD_*.csv") )
                if [[ ! -f "$measurement" ]]; then
                    rm -f perf.txt output.txt
                    measure_failed_to "measure"; continue                   
                fi
 
                if ! measure_verify_command; then
                    rm -f "$measurement" perf.txt output.txt
                    if $MEASURE_STOP; then
                        exit 1
                    fi
                    continue
                fi
                rm -f output.txt
            done

            exit 0
        fi
    fi

    if [[ ${#MEASURE_LANG[@]} -eq 0 ]]; then
        MEASURE_LANG=($(find "$MEASURE_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort))
        if [[ ${#MEASURE_LANG[@]} -eq 0 ]]; then
            error "No language dirs found in \"$MEASURE_DIR\"."
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

    measure_setup
    measure_splash

    if [[ $MEASURE_SLEEP -gt 0 ]]; then
        info "Starting measurements in ${MEASURE_SLEEP}s."; sleep $MEASURE_SLEEP
    fi

    pushd "$MEASURE_DIR" >/dev/null

    for conf in "${MEASURE_CONF[@]}"; do
        for lang in "${MEASURE_LANG[@]}"; do
            for bench in "${MEASURE_BENCH[@]}"; do
                bench_dir="$lang/$bench"
                if [[ ! -d "$bench_dir" ]]; then
                    continue
                fi

                pushd "$bench_dir" >/dev/null

                info "Measuring $lang $bench with $conf.\n"

                if ! make clean >/dev/null; then
                    measure_failed_to "clean"; continue
                fi

                if ! make all >/dev/null; then
                    measure_failed_to "build"; continue
                fi

                if ! eval $(measure_build_command "$conf"); then
                    rm -f perf.txt output.txt
                    measure_failed_to "measure"; continue                    
                fi

                local measurement=( $(find . -maxdepth 1 -type f -name "Intel_*.csv" -o -name "AMD_*.csv") )
                if [[ ! -f "$measurement" ]]; then
                    rm -f perf.txt output.txt
                    measure_failed_to "measure"; continue                   
                fi

                if ! measure_verify_command; then
                    rm -f "$measurement" perf.txt output.txt
                    if $MEASURE_STOP; then
                        exit 1
                    fi
                    continue
                fi

                rm -f output.txt
                local results_dir="../../../results/$conf/$lang/$bench"
                mkdir -p "$results_dir"
                mv "$measurement" perf.txt "$results_dir"

                if [[ $MEASURE_SLEEP -gt 0 ]]; then
                    info "Sleeping for ${MEASURE_SLEEP}s."; sleep $MEASURE_SLEEP
                fi

                popd >/dev/null
            done
        done
    done

    popd >/dev/null
}
