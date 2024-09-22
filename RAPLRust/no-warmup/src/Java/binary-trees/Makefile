compile:
	cp binarytrees.java-7.java binarytrees.java
	javac -d . binarytrees.java

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "java binarytrees 21"

run:
	java binarytrees 21

mem:
	time -v java binarytrees 21

valgrind:
	valgrind --tool=massif --stacks=yes java binarytrees 21
