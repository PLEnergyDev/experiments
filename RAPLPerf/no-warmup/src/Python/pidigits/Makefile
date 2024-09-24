compile:
	cp pidigits.python3-2.python3 pidigits.python3-2.py

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "python3 -OO pidigits.python3-2.py 10000"

run:
	python3 -OO pidigits.python3-2.py 10000
mem:
	time -v python3 -OO pidigits.python3-2.py 10000
