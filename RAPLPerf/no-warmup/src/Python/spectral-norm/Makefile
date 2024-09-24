compile:
	cp spectralnorm.python3-5.python3 spectralnorm.python3-5.py

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "python3 -OO spectralnorm.python3-5.py 5500"

run:
	python3 -OO spectralnorm.python3-5.py 5500

mem:
	time -v python3 -OO spectralnorm.python3-5.py 5500
