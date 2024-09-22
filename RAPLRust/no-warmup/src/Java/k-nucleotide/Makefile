compile:
	javac -d . -cp .:/usr/local/src/java-libs/fastutil-7.0.12.jar knucleotide.java

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "java  -cp .:/usr/local/src/java-libs/fastutil-7.0.12.jar knucleotide 0 < ../../knucleotide-input25000000.txt"

run:
	java  -cp .:/usr/local/src/java-libs/fastutil-7.0.12.jar knucleotide 0 < ../../knucleotide-input25000000.txt

mem:
	time -v  java  -cp .:/usr/local/src/java-libs/fastutil-7.0.12.jar knucleotide 0 < ../../knucleotide-input25000000.txt

valgrind:
	valgrind --tool=massif --stacks=yes java -cp .:/usr/local/src/java-libs/fastutil-7.0.12.jar knucleotide 0 < ../../knucleotide-input25000000.txt
