compile:
	cp regexredux.python3 regexredux.py
measure:
	sudo modprobe msr
	sudo ../../RAPL/main "python3 -OO regexredux.py 0 < ../../regexredux-input5000000.txt" Python regex-redux

run:
	python3 -OO regexredux.py 0 < ../../regexredux-input5000000.txt

mem:
	time -v python3 -OO regexredux.py 0 < ../../regexredux-input5000000.txt
