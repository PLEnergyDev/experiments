compile:
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native  pidigits.c -o pidigits.gcc_run -lgmp
measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./pidigits.gcc_run 10000"

run:
	./pidigits.gcc_run 10000
mem:
	time -v ./pidigits.gcc_run 10000
