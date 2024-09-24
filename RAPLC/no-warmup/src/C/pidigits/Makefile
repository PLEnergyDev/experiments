CC=gcc

OPT_FLAGS=-pipe -Wall -O3 -fomit-frame-pointer -march=native
LIB_FLAGS=-lgmp
CFLAGS=$(OPT_FLAGS)

TARGET=main
SRC=$(TARGET).c

RAPL=../../RAPL/main

INPUT=10000

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS) $(LIB_FLAGS)

run: $(TARGET)
	./$(TARGET) $(INPUT)

measure: $(TARGET)
	modprobe msr
	$(RAPL) "./$(TARGET) $(INPUT)" C pidigits

mem: $(TARGET)
	time -v ./$(TARGET) $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem
