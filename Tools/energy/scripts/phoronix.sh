#!/bin/bash

PTS_TAR="/opt/pts.tar.gz"
PTS_EXE="/opt/phoronix-test-suite/phoronix-test-suite"

phoronix_main() {
    if [[ -z "$1" ]]; then
        error "Undefined Phoronix workload"
    fi

    if [[ ! -f "$PTS_EXE" ]]; then
        wget -q --show-progress "https://github.com/phoronix-test-suite/phoronix-test-suite/releases/download/v10.8.4/phoronix-test-suite-10.8.4.tar.gz" -O "$PTS_TAR"

        if [[ ! -f "$PTS_TAR" ]]; then
            error "Download failed!"
        fi

        tar -xzf "$PTS_TAR" -C "/opt"

        if [[ ! -f "$PTS_EXE" ]]; then
            error "Extraction failed or Phoronix Test Suite not found!"
        fi
    fi

    # Sufficiently large integer ensuring an 'infinite' loop of one workload
    # Phoronix suite will be automatically stopped when the benchmark ends
    TOTAL_LOOP_COUNT=999999 bash -c "echo \"n\" | $PTS_EXE default-benchmark $1 >/dev/null &" || error "Phornoix workload failed to start"
}

phoronix_clean() {
    pkill -fi -9 phoronix >/dev/null

    while pgrep -f phoronix >/dev/null; do
        sleep 0.5
    done
}
