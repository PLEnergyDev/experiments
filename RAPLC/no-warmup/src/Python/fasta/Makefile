compile:
	cp fasta.python3-3.python3 fasta.python3-3.py
measure:
	sudo modprobe msr
	sudo ../../RAPL/main "python3 -OO fasta.python3-3.py 25000000" Python fasta

run:
	python3 -OO fasta.python3-3.py 25000000

make mem:
	time -v  python3 -OO fasta.python3-3.py 25000000
