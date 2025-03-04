SHELL := /bin/bash

CC=dotnet

CFLAGS=-c Release

TARGET=bin/Release/net8.0/program
SRC=Program.cs

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
	rm -rf bin obj

.PHONY: all run mem measure measure_no-warmup measure_warmup clean valgrind

.SILENT:
