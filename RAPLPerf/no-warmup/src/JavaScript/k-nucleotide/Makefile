compile:
	cp -L knucleotide.node-2.node knucleotide.node-2.js

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "node --no-deprecation knucleotide.node-2.js 0 < ../../knucleotide-input25000000.txt"

run:
	node --no-deprecation knucleotide.node-2.js 0 < ../../knucleotide-input25000000.txt

mem:
	time -v node --no-deprecation knucleotide.node-2.js 0 < ../../knucleotide-input25000000.txt

valgrind:
	valgrind --tool=massif --stacks=yes node --no-deprecation knucleotide.node-2.js 0 < ../../knucleotide-input25000000.txt
