compile:
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -std=c99 -mfpmath=sse -msse3 -fopenmp fasta.gcc-2.c -o fasta.gcc-2.gcc_run
	
measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./fasta.gcc-2.gcc_run 25000000"

run:
	./fasta.gcc-2.gcc_run 25000000

mem:
	time -v ./fasta.gcc-2.gcc_run 25000000
