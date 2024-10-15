compile:
	cp nbody.python3 nbody.py

measure:
	modprobe msr
	sudo ../../RAPL/main "python3 -OO nbody.py 50000000"

run:
	python3 -OO nbody.py 50000000

mem:
	time -v python3 -OO nbody.py 50000000
