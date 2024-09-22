compile:
	cp mandelbrot.java-2.java mandelbrot.java
	javac -d . mandelbrot.java

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "java   mandelbrot 16000"

run:
	java mandelbrot 16000

mem:
	time -v java mandelbrot 16000

valgrind:
	valgrind --tool=massif --stacks=yes java mandelbrot 16000
