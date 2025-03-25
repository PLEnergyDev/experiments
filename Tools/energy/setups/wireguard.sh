#!/bin/bash

source "$SCRIPTS_DIR/phoronix.sh"
source "$SETUPS_DIR/production.sh"

wireguard_main() {
    info "Starting wireguard workload..."
    production_main
    phoronix_main "system/wireguard"
}

wireguard_clean() {
    phoronix_clean

    info "Killing all GIMP workloads..."
    pkill -fi -9 wireguard >/dev/null

    while pgrep -fi wireguard >/dev/null; do
        sleep 0.5
    done
}
