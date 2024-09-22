compile:
	cargo build --release

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./target/release/fasta 25000000"

run:
	./target/release/fasta 25000000

mem:
	time -v ./target/release/fasta 25000000

valgrind:
	valgrind --tool=massif --stacks=yes ./target/release/fasta 25000000
