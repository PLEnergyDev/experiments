compile:
	cargo build --release

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./target/release/k-nucleotide 0 < ../../knucleotide-input25000000.txt"

run:
	./target/release/k-nucleotide 0 < ../../knucleotide-input25000000.txt

mem:
	time -v ./target/release/k-nucleotide 0 < ../../knucleotide-input25000000.txt

valgrind:
	valgrind --tool=massif --stacks=yes ./target/release/k-nucleotide 0 < ../../knucleotide-input25000000.txt
