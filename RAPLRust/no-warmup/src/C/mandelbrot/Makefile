compile:
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -mno-fma -fno-finite-math-only -mfpmath=sse -msse2 -fopenmp mandelbrot.gcc-6.c -o mandelbrot.gcc-6.gcc_run
measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./mandelbrot.gcc-6.gcc_run 16000"

run:
	./mandelbrot.gcc-6.gcc_run 16000

mem:
	time -v ./mandelbrot.gcc-6.gcc_run 16000
