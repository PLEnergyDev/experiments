compile:
	cp -L mandelbrot.node mandelbrot.js
measure:
	sudo modprobe msr
	sudo ../../RAPL/main "node mandelbrot.js 16000" JavaScript mandelbrot

run:
	node --no-deprecation mandelbrot.js 16000

mem:
	time -v node mandelbrot.js 16000

valgrind:
	valgrind --tool=massif --stacks=yes node --no-deprecation mandelbrot.js 16000
