compile:
	cp -L fasta.node-4.node fasta.node-4.js

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "node --no-deprecation fasta.node-4.js 25000000"

run:
	node --no-deprecation fasta.node-4.js 25000000

mem:
	time -v node --no-deprecation fasta.node-4.js 25000000


valgrind:
	valgrind --tool=massif --stacks=yes node --no-deprecation fasta.node-4.js 25000000

