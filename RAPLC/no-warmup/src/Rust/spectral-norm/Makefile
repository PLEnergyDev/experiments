compile:
	cargo build --release

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "./target/release/spectral-norm 5500" Rust spectral-norm

run:
	./target/release/spectral-norm 5500

mem:
	time -v ./target/release/spectral-norm 5500

valgrind:
	valgrind --tool=massif --stacks=yes ./target/release/spectral-norm 5500
