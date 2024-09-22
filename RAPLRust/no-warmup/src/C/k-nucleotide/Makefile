compile:
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -fopenmp -std=c99 -IInclude knucleotide.c -o knucleotide.gcc_run

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./knucleotide.gcc_run 0 < ../../knucleotide-input25000000.txt"

run:
	./knucleotide.gcc_run 0 < ../../knucleotide-input25000000.txt

mem:
	time -v ./knucleotide.gcc_run 0 < ../../knucleotide-input25000000.txt
