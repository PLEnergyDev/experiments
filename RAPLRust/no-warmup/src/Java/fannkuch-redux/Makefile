compile:
	javac -d . fannkuchredux.java

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "java fannkuchredux 12"

run:
	java fannkuchredux 12

mem:
	time -v java fannkuchredux 12

valgrind:
	valgrind --tool=massif --stacks=yes java fannkuchredux 12
