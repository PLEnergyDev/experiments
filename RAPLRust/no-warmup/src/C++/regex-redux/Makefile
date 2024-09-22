compile:
	g++ -c -pipe -O3 -fomit-frame-pointer -march=native  -fopenmp regexredux.gpp-3.c++ -o regexredux.gpp-3.c++.o &&  g++ regexredux.gpp-3.c++.o -o regexredux.gpp-3.gpp_run -fopenmp -lboost_regex 

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./regexredux.gpp-3.gpp_run 0 < ../../regexredux-input5000000.txt"

run:
	./regexredux.gpp-3.gpp_run 0 < ../../regexredux-input5000000.txt

mem:
	time -v ./regexredux.gpp-3.gpp_run 0 < ../../regexredux-input5000000.txt

valgrind:
	valgrind --tool=massif --stacks=yes ./regexredux.gpp-3.gpp_run 0 < ../../regexredux-input5000000.txt
