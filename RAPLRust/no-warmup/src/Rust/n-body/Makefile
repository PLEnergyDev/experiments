compile:
	cargo build --release

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./target/release/n-body 50000000"

run:
	./target/release/n-body 50000000

mem:
	time -v ./target/release/n-body 50000000

valgrind:
	valgrind --tool=massif --stacks=yes ./target/release/n-body 50000000
