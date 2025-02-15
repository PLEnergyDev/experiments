SHELL := /bin/bash

CC=gcc

RAPL_DIR=../../../lib/rapl-interface
RAPL=$(RAPL_DIR)/target/release/librapl_lib.so

RAPL_FLAGS=-L$(RAPL_DIR)/target/release -lrapl_lib -Wl,-rpath=$(RAPL_DIR)/target/release
CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS) $(RAPL_FLAGS)

TARGET=main
SRC=$(TARGET).c

COUNT?=45
CACHE_MEASURE_FREQ_MS?=500

MODE?=no-warmup

$(RAPL):
	@echo "Building rapl-interface with cargo in release mode..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) 1 $(INPUT)

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) 1 $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind

include ../$(MODE).mk
