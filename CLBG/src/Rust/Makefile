SHELL := /bin/bash

CC=cargo

CFLAGS=--release

TARGET=target/release/main
SRC=src/main.rs

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) build $(CFLAGS)

run: $(TARGET)
	./$(TARGET) $(INPUT)

mem: $(TARGET)
	time -v ./$(TARGET) $(INPUT)

measure: $(TARGET)
	./$(TARGET) $(INPUT)

valgrind: $(TARGET)
	valgrind --tool=massif --stacks=yes ./$(TARGET) $(INPUT)

clean:
	$(CC) clean

.PHONY: all run mem measure measure_no-warmup measure_warmup clean valgrind

.SILENT:
