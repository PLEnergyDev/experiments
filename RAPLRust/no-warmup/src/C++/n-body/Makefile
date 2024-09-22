compile:
	g++ -c -pipe -O3 -fomit-frame-pointer -march=native -mfpmath=sse -msse3 --std=c++11 nbody.gpp-8.c++ -o nbody.gpp-8.c++.o &&  g++ nbody.gpp-8.c++.o -o nbody.gpp-8.gpp_run -fopenmp

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./nbody.gpp-8.gpp_run 50000000"

run:
	./nbody.gpp-8.gpp_run 50000000

mem:
	time -v ./nbody.gpp-8.gpp_run 50000000

valgrind:
	valgrind --tool=massif --stacks=yes ./nbody.gpp-8.gpp_run 50000000


