compile:
	cp fasta.java-5.java fasta.java
	javac -d . fasta.java

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "java fasta 25000000"

run:
	java fasta 25000000

mem:
	time -v java fasta 25000000

valgrind:
	valgrind --tool=massif --stacks=yes java fasta 25000000
