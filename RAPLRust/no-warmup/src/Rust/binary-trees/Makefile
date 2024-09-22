compile:
	cargo build --release

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./target/release/binary-trees 21"

run:
	./target/release/binary-trees 21

mem:
	time -v ./target/release/binary-trees 21

valgrind:
	valgrind --tool=massif --stacks=yes ./target/release/binary-trees 21 
