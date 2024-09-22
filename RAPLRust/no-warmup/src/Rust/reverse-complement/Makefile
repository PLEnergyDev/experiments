compile:
	cargo build --release

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./target/release/reverse-complement 0 < ../../revcomp-input25000000.txt"

run:
	./target/release/reverse-complement 0 < ../../revcomp-input25000000.txt

mem:
	time -v ./target/release/reverse-complement 0 < ../../revcomp-input25000000.txt

valgrind:
	valgrind --tool=massif --stacks=yes ./target/release/reverse-complement 0 < ../../revcomp-input25000000.txt
