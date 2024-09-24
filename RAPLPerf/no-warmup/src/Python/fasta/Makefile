compile:
	cp fasta.python3-3.python3 fasta.python3-3.py

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "python3 -OO fasta.python3-3.py 25000000"

run:
	python3 -OO fasta.python3-3.py 25000000

make mem:
	time -v  python3 -OO fasta.python3-3.py 25000000
