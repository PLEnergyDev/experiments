compile:
	cp nbody.python3 nbody.py
measure:
	sudo modprobe msr
	sudo ../../RAPL/main "python3 -OO nbody.py 50000000" Python n-body

run:
	python3 -OO nbody.py 50000000

mem:
	time -v python3 -OO nbody.py 50000000
