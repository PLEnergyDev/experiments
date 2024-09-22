#!/bin/bash

HOSTNAME="seff_jr"
IP="192.168.0.5"

# getting time
time=$(date -I)

# adding time to folder name
mv results results_$time

# Send entire results dir to Raspberry Pi
# moving results folder to Raspberry Pi (r for recursive)
scp -r results_$time $HOSTNAME@$IP:results/
