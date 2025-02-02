SHELL := /bin/bash

CC=g++

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native -std=c++14
LIB_FLAGS=-Wl,--no-as-needed -lpthread -lapr-1 -L$(RAPL_DIR)/target/release -lrapl_lib -Wl,-rpath=$(RAPL_DIR)/target/release

CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS)

TARGET=main
SRC=$(TARGET).cpp

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
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) 1 < $(INPUT)

measure: $(TARGET) $(RAPL)
	perf stat --all-cpus -I $(CACHE_MEASURE_FREQ_MS) \
		--append --output cache.txt \
		-e cache-misses,cache-references,LLC-loads-misses,LLC-loads \
		./$(TARGET) $(COUNT) < $(INPUT)

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) 1 < $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 < $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
