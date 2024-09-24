CC=gcc

OPT_FLAGS=-pipe -Wall -O3 -fomit-frame-pointer -march=native -fopenmp -std=c99
INCLUDE_FLAGS=-IInclude

CFLAGS=$(OPT_FLAGS) $(INCLUDE_FLAGS)

TARGET=main
SRC=$(TARGET).c

RAPL=../../RAPL/main

INPUT=../../knucleotide-input25000000.txt

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) < $(INPUT)

measure: $(TARGET)
	modprobe msr
	$(RAPL) "./$(TARGET) < $(INPUT)" C k-nucleotide

mem: $(TARGET)
	time -v ./$(TARGET) < $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem
