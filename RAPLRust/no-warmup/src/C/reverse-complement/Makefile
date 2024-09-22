compile:
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -funroll-loops -fopenmp revcomp.gcc-6.c -o revcomp.gcc-6.gcc_run 

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./revcomp.gcc-6.gcc_run 0 < ../../revcomp-input25000000.txt"

run:
	./revcomp.gcc-6.gcc_run 0 < ../../revcomp-input25000000.txt

mem:
	time -v ./revcomp.gcc-6.gcc_run 0 < ../../revcomp-input25000000.txt
