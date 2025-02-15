SHELL := /bin/bash

CC=cargo

CFLAGS=--release

TARGET=target/release/main
SRC=src/main.rs

RAPL_DIR=../../../lib/rapl-interface
RAPL=$(RAPL_DIR)/target/release/librapl_lib.so

COUNT?=45
CACHE_MEASURE_FREQ_MS?=500

MODE?=no-warmup

$(RAPL):
	@echo "Building rapl-interface with cargo in release mode..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) build $(CFLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) 1 $(INPUT)

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) 1 $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 $(INPUT)

clean:
	$(CC) clean

.PHONY: all clean run measure mem valgrind

include ../$(MODE).mk