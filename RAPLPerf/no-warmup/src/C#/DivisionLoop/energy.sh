#!/bin/sh

if test "$1" != "" ; then 
    echo "INFO: Running $1 iterations"
else
    echo "INFO: Need to specify number of iterations"
    exit 1
fi

sudo make clean
sudo make

for i in {1..$1}; do
	sudo -E perf stat --all-cpus --no-scale --no-big-num \
	--append --output results.txt \
	-e power/energy-pkg/,power/energy-ram/,msr/cpu_thermal_margin/ \
	-- make run
done
