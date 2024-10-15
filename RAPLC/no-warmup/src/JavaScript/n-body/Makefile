compile:
	cp -L nbody.node nbody.js

measure:
	modprobe msr
	sudo ../../RAPL/main "node --no-deprecation nbody.js 50000000"

run:
	node --no-deprecation nbody.js 50000000

mem:
	time -v node --no-deprecation nbody.js 50000000

valgrind:
	valgrind --tool=massif --stacks=yes  node --no-deprecation nbody.js 50000000
