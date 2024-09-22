compile:
	cp -L binarytrees.node binarytrees.js

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "node --no-deprecation binarytrees.js 21"

run:
	node --no-deprecation binarytrees.js 21

mem:
	time -v node --no-deprecation binarytrees.js 21

valgrind:
	valgrind --tool=massif --stacks=yes node --no-deprecation binarytrees.js 21
