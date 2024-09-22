compile:
	cargo build --release

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "./target/release/fannkuch-redux 12"

run:
	./target/release/fannkuch-redux 12

mem:
	time -v ./target/release/fannkuch-redux 12

valgrind:
	valgrind --tool=massif --stacks=yes ./target/release/fannkuch-redux 12
