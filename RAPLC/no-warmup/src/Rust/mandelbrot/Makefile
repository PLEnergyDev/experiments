compile:
	cargo build --release

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "./target/release/mandelbrot 16000" Rust mandelbrot

run:
	./target/release/mandelbrot 16000

mem:
	time -v  ./target/release/mandelbrot 16000

valgrind:
	valgrind --tool=massif --stacks=yes  ./target/release/mandelbrot 16000
