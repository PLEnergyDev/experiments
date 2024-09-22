compile:
	cargo build --release

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./target/release/regex-redux 0 < ../../regexredux-input5000000.txt"

run:
	./target/release/regex-redux 0 < ../../regexredux-input5000000.txt

mem:
	time -v ./target/release/regex-redux 0 < ../../regexredux-input5000000.txt

valgrind:
	valgrind --tool=massif --stacks=yes ./target/release/regex-redux 0 < ../../regexredux-input5000000.txt
