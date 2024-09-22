compile:
	cp revcomp.java-3.java revcomp.java
	javac -d . revcomp.java

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "java revcomp 0 < ../../revcomp-input25000000.txt"

run:
	java revcomp 0 < ../../revcomp-input25000000.txt

mem:
	time -v java revcomp 0 < ../../revcomp-input25000000.txt

valgrind:
	valgrind --tool=massif --stacks=yes java revcomp 0 < ../../revcomp-input25000000.txt
