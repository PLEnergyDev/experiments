compile:
	cp -L mandelbrot.node mandelbrot.js

measure:
	modprobe msr
	sudo ../../RAPL/target/release/RAPL "node mandelbrot.js 16000"

run:
	node --no-deprecation mandelbrot.js 16000

mem:
	time -v node mandelbrot.js 16000

valgrind:
	valgrind --tool=massif --stacks=yes node --no-deprecation mandelbrot.js 16000
