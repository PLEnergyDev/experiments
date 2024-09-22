compile:
	cp spectralnorm.java-2.java spectralnorm.java
	javac -d . spectralnorm.java

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "java spectralnorm 5500"

run:
	java spectralnorm 5500

mem:
	time -v java spectralnorm 5500

valgrind:
	valgrind --tool=massif --stacks=yes java spectralnorm 5500
