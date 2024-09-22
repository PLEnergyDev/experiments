compile:
	cargo build --release

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "./target/release/fasta 25000000" Rust fasta

run:
	./target/release/fasta 25000000

mem:
	time -v ./target/release/fasta 25000000

valgrind:
	valgrind --tool=massif --stacks=yes ./target/release/fasta 25000000
