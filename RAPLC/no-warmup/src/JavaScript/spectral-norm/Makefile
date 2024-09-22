compile:
	cp -L spectralnorm.node-2.node spectralnorm.node-2.js
measure:
	sudo modprobe msr
	sudo ../../RAPL/main "node --no-deprecation spectralnorm.node-2.js 5500" JavaScript spectral-norm

run:
	node --no-deprecation spectralnorm.node-2.js 5500

mem:
	time -v node --no-deprecation spectralnorm.node-2.js 5500

valgrind:
	valgrind --tool=massif --stacks=yes node --no-deprecation spectralnorm.node-2.js 5500
