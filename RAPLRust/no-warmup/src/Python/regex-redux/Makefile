compile:
	cp regexredux.python3 regexredux.py

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "python3 -OO regexredux.py 0 < ../../regexredux-input5000000.txt"

run:
	python3 -OO regexredux.py 0 < ../../regexredux-input5000000.txt

mem:
	time -v python3 -OO regexredux.py 0 < ../../regexredux-input5000000.txt
