compile:
	g++ -c -pipe -O3 -fomit-frame-pointer -march=native  -std=c++11 -fopenmp fannkuchredux.gpp-5.c++ -o fannkuchredux.gpp-5.c++.o && g++ fannkuchredux.gpp-5.c++.o -o fannkuchredux.gpp-5.gpp_run -fopenmp 

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./fannkuchredux.gpp-5.gpp_run 12"

run:
	./fannkuchredux.gpp-5.gpp_run 12

mem:
	time -v  ./fannkuchredux.gpp-5.gpp_run 12

valgrind:
	valgrind --tool=massif --stacks=yes  ./fannkuchredux.gpp-5.gpp_run 12

