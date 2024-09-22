compile:
	cp nbody.java-4.java nbody.java
	javac -d . nbody.java

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "java nbody 50000000"

run:
	java nbody 50000000

mem:
	time -v java nbody 50000000

valgrind:
	valgrind --tool=massif --stacks=yes java nbody 50000000
