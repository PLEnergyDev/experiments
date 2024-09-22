compile:
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -pthread chameneosredux.gcc-5.c -o chameneosredux.gcc-5.gcc_run
	
measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./chameneosredux.gcc-5.gcc_run 6000000"

run:
	./chameneosredux.gcc-5.gcc_run 6000000

mem:
	time -v ./chameneosredux.gcc-5.gcc_run 6000000
