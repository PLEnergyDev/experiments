SHELL := /bin/bash

CC=g++

RAPL_FLAGS=-lrapl_interface -Wl,-rpath=/usr/local/lib
CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS) $(RAPL_FLAGS)

TARGET=main
SRC=$(TARGET).cpp

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) $(INPUT)

mem: $(TARGET)
	time -v ./$(TARGET) $(INPUT)

measure: $(TARGET)
	./$(TARGET) $(INPUT)

valgrind: $(TARGET)
	valgrind --tool=massif --stacks=yes ./$(TARGET) $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all run mem measure measure_no-warmup measure_warmup clean valgrind

.SILENT:
