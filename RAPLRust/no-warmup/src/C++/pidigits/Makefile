compile:
	g++ -c -pipe -O3 -fomit-frame-pointer -march=native  -std=c++14 -g pidigits.gpp-4.c++ -o pidigits.gpp-4.c++.o &&  g++ pidigits.gpp-4.c++.o -o pidigits.gpp-4.gpp_run -lgmp -lgmpxx 

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./pidigits.gpp-4.gpp_run 10000"

run:
	./pidigits.gpp-4.gpp_run 10000

mem:
	time -v ./pidigits.gpp-4.gpp_run 10000

valgrind:
	valgrind --tool=massif --stacks=yes ./pidigits.gpp-4.gpp_run 10000
