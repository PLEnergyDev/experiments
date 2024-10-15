compile:
	cp -L fannkuchredux.node-4.node fannkuchredux.node-4.js

measure:
	modprobe msr
	sudo ../../RAPL/main "node --no-deprecation fannkuchredux.node-4.js 12"

run:
	node --no-deprecation fannkuchredux.node-4.js 12

mem:
	time -v node --no-deprecation fannkuchredux.node-4.js 12

valgrind:
	valgrind --tool=massif --stacks=yes node --no-deprecation fannkuchredux.node-4.js 12
