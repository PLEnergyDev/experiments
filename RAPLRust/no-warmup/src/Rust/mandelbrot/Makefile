compile:
	cargo build --release

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./target/release/mandelbrot 16000"

run:
	./target/release/mandelbrot 16000

mem:
	time -v  ./target/release/mandelbrot 16000

valgrind:
	valgrind --tool=massif --stacks=yes  ./target/release/mandelbrot 16000
