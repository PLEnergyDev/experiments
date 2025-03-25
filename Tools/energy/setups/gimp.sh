#!/bin/bash

source "$SCRIPTS_DIR/phoronix.sh"
source "$SETUPS_DIR/production.sh"

gimp_main() {
    info "Starting GIMP workload..."
    production_main
    phoronix_main "system/gimp"
}

gimp_clean() {
    phoronix_clean

    info "Killing all GIMP workloads..."
    pkill -fi -9 gimp >/dev/null

    while pgrep -fi gimp >/dev/null; do
        sleep 0.5
    done
}
