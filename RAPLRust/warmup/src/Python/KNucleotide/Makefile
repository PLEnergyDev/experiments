CC=python3
CFLAGS=-OO

SRC=main.py

COUNT=20
INPUT=

run:
	$(CC) $(CFLAGS) $(SRC) 1 < ../../knucleotide-input25000000.txt

measure:
	modprobe msr
	$(CC) $(CFLAGS) $(SRC) $(COUNT) < ../../knucleotide-input25000000.txt

mem:
	time -v $(CC) $(CFLAGS) $(SRC) 1 < ../../knucleotide-input25000000.txt

clean:
