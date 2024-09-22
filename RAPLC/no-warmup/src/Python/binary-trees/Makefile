compile:
	cp binarytrees.python3 binarytrees.py
measure:
	sudo modprobe msr
	sudo ../../RAPL/main "python3 -OO binarytrees.py 21" Python binary-trees

run:
	python3 -OO binarytrees.py 21

mem:
	time -v python3 -OO binarytrees.py 21
