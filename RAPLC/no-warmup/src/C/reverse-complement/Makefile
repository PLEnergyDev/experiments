CC=gcc

OPT_FLAGS=-pipe -Wall -O3 -fomit-frame-pointer -march=native -funroll-loops -fopenmp
CFLAGS=$(OPT_FLAGS)

TARGET=main
SRC=$(TARGET).c

RAPL=../../RAPL/main

INPUT=../../revcomp-input25000000.txt

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) < $(INPUT)

measure: $(TARGET)
	modprobe msr
	$(RAPL) "./$(TARGET) < $(INPUT)" C reverse-complement

mem: $(TARGET)
	time -v ./$(TARGET) < $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem
