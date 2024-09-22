compile:
	cargo build --release

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "./target/release/binary-trees 21" Rust binary-trees

run:
	./target/release/binary-trees 21

mem:
	time -v ./target/release/binary-trees 21

valgrind:
	valgrind --tool=massif --stacks=yes ./target/release/binary-trees 21 
