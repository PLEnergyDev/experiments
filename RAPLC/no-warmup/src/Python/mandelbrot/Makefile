compile:
	cp mandelbrot.python3-7.python3 mandelbrot.python3-7.py

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "python3 -OO mandelbrot.python3-7.py 16000"

run:
	python3 -OO mandelbrot.python3-7.py 16000

mem:
	time -v python3 -OO mandelbrot.python3-7.py 16000
