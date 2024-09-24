compile:
	cp fannkuchredux.python3-4.python3 fannkuchredux.python3-4.py

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "python3 -OO fannkuchredux.python3-4.py 12"

run:
	python3 -OO fannkuchredux.python3-4.py 12
mem:
	time -v python3 -OO fannkuchredux.python3-4.py 12
