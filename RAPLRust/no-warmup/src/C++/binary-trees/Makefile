compile:
	g++ -c -pipe -O3 -fomit-frame-pointer -march=native  -std=c++14 -fopenmp -I/usr/include/apr-1.0 binarytrees.gpp-9.c++ -o binarytrees.gpp-9.c++.o &&  g++ binarytrees.gpp-9.c++.o -o binarytrees.gpp-9.gpp_run -fopenmp -lapr-1 

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./binarytrees.gpp-9.gpp_run 21"

run:
	./binarytrees.gpp-9.gpp_run 21

mem:
	time -v ./binarytrees.gpp-9.gpp_run 21

valgrind:
	valgrind --tool=massif --stacks=yes ./binarytrees.gpp-9.gpp_run 21
