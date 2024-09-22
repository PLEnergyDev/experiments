CC=python3
CFLAGS=-OO

SRC=main.py

COUNT=20
INPUT=16000

run:
	$(CC) $(CFLAGS) $(SRC) 1 $(INPUT)

measure:
	modprobe msr
	$(CC) $(CFLAGS) $(SRC) $(COUNT) $(INPUT)

mem:
	time -v $(CC) $(CFLAGS) $(SRC) 1 $(INPUT)

clean:
