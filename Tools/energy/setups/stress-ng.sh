#!/bin/bash

PTS_WORKLOAD="pts/stress-ng"

source "$SETUPS_DIR/production.sh"

source "$SCRIPTS_DIR/phoronix.sh"

measure_set_cleanup "info \"Killing all Gimp workloads...\"; pkill -fi -9 stress-ng >/dev/null"
