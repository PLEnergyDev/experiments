compile:
	cargo build --release

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./target/release/spectral-norm 5500"

run:
	./target/release/spectral-norm 5500

mem:
	time -v ./target/release/spectral-norm 5500

valgrind:
	valgrind --tool=massif --stacks=yes ./target/release/spectral-norm 5500
