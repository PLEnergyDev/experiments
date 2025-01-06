SHELL := /bin/bash

CC=gcc

OPT_FLAGS=-pipe -Wall -O3 -fomit-frame-pointer -march=ivybridge -fopenmp
LIB_FLAGS=-lm -L$(RAPL_DIR)/target/release -lrapl_lib -Wl,-rpath=$(RAPL_DIR)/target/release

CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS)

TARGET=main
SRC=$(TARGET).c

RAPL_DIR=../../rapl-interface
RAPL=$(RAPL_DIR)/target/release/librapl_lib.so

COUNT=45
CACHE_MEASURE_FREQ_MS=500
INPUT=5500

$(RAPL):
	@echo "Building rapl-interface with cargo in release mode..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) 1 $(INPUT)

measure: $(TARGET) $(RAPL)
	perf stat --all-cpus -I $(CACHE_MEASURE_FREQ_MS) \
		--append --output cache.txt \
		-e cache-misses,cache-references,LLC-load-misses,LLC-loads \
		bash -c 'for i in $$(seq 1 $(COUNT)); do \
			./$(TARGET) 1 $(INPUT); \
		done'

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) 1 $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
