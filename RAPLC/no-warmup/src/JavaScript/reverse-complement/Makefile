compile:
	cp -L revcomp.node-7.node revcomp.node-7.js

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "node --no-deprecation revcomp.node-7.js 0 < ../../revcomp-input25000000.txt"

run:
	node --no-deprecation revcomp.node-7.js 0 < ../../revcomp-input25000000.txt

mem:
	time -v node --no-deprecation revcomp.node-7.js 0 < ../../revcomp-input25000000.txt

valgrind:
	valgrind --tool=massif --stacks=yes node --no-deprecation revcomp.node-7.js 0 < ../../revcomp-input25000000.txt
