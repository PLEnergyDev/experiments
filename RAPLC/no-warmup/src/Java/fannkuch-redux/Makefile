compile:
	javac -d . fannkuchredux.java

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "java fannkuchredux 12" Java fannkuch-redux

run:
	java fannkuchredux 12

mem:
	time -v java fannkuchredux 12

valgrind:
	valgrind --tool=massif --stacks=yes java fannkuchredux 12
