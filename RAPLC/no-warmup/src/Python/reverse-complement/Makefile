compile:
	cp revcomp.python3-6.python3 revcomp.python3-6.py

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "python3 -OO revcomp.python3-6.py 0 < ../../revcomp-input25000000.txt"

run:
	python3 -OO revcomp.python3-6.py 0 < ../../revcomp-input25000000.txt

mem:
	time -v python3 -OO revcomp.python3-6.py 0 < ../../revcomp-input25000000.txt

