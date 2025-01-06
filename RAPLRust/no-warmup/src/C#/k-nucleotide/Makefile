SHELL := /bin/bash

CC=dotnet

CFLAGS=-c Release

TARGET=bin/Release/net8.0/k-nucleotide
SRC=Program.cs

RAPL_DIR=../../rapl-interface
RAPL=$(RAPL_DIR)/target/release/librapl_lib.so

COUNT=45
CACHE_MEASURE_FREQ_MS=500
INPUT=../../knucleotide-input25000000.txt

$(RAPL):
	@echo "Building rapl-interface with cargo in release mode..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) build $(CFLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) 1 < $(INPUT)

measure: $(TARGET) $(RAPL)
	perf stat --all-cpus -I $(CACHE_MEASURE_FREQ_MS) \
		--append --output cache.txt \
		-e cache-misses,cache-references,LLC-load-misses,LLC-loads \
		bash -c 'for i in $$(seq 1 $(COUNT)); do \
			./$(TARGET) 1 < $(INPUT); \
		done'

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) 1 < $(INPUT)

valgrind: $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 < $(INPUT)

clean:
	rm -rf bin obj

.PHONY: all clean run measure mem valgrind
