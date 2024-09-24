compile:
	cp nbody.python3 nbody.py

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "python3 -OO nbody.py 50000000"

run:
	python3 -OO nbody.py 50000000

mem:
	time -v python3 -OO nbody.py 50000000
