compile:
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -mfpmath=sse -msse3 nbody.gcc-4.c -o nbody.gcc-4.gcc_run -lm

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./nbody.gcc-4.gcc_run 50000000"

run:
	./nbody.gcc-4.gcc_run 50000000

mem:
	time -v ./nbody.gcc-4.gcc_run 50000000
