compile:
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -fopenmp regexredux.gcc-4.c -o regexredux.gcc-4.gcc_run -lpcre

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./regexredux.gcc-4.gcc_run 0 < ../../regexredux-input5000000.txt"

run:
	./regexredux.gcc-4.gcc_run 0 < ../../regexredux-input5000000.txt
mem:
	time -v ./regexredux.gcc-4.gcc_run 0 < ../../regexredux-input5000000.txt
