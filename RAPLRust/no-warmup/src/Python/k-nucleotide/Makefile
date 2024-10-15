compile:
	cp knucleotide.python3-3.python3 knucleotide.python3-3.py

measure:
	modprobe msr
	sudo ../../RAPL/main "python3 -OO knucleotide.python3-3.py 0 < ../../knucleotide-input25000000.txt"

run:
	python3 -OO knucleotide.python3-3.py 0 < ../../knucleotide-input25000000.txt

mem:
	time -v python3 -OO knucleotide.python3-3.py 0 < ../../knucleotide-input25000000.txt
