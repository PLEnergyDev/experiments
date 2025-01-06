SHELL := /bin/bash

CC=dotnet

CFLAGS=-c Release

TARGET=bin/Release/net8.0/division-loop
SRC=Program.cs

RAPL_DIR=../../rapl-interface
RAPL=$(RAPL_DIR)/target/release/librapl_lib.so

COUNT=45
CACHE_MEASURE_FREQ_MS=500
INPUT=20

DOTNET_JitDisasmOnlyOptimized=1
DOTNET_JitDisasmDiffable=1
DOTNET_JitStdOutFile=jit.txt
DOTNET_JitDisasm=DivisionLoop:Run

$(RAPL):
	@echo "Building rapl-interface with cargo in release mode..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) build $(CFLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) 1 $(INPUT)

measure: $(TARGET) $(RAPL)
	perf stat --all-cpus -I $(CACHE_MEASURE_FREQ_MS) \
		--append --output cache.txt \
		-e cache-misses,cache-references,LLC-loads-misses,LLC-loads \
		./$(TARGET) $(COUNT) $(INPUT)

jit: $(TARGET) $(RAPL)
	perf stat --all-cpus -I $(CACHE_MEASURE_FREQ_MS) \
		--append --output cache.txt \
		-e cache-misses,cache-references,LLC-loads-misses,LLC-loads \
		env DOTNET_JitStdOutFile=$(DOTNET_JitStdOutFile) DOTNET_JitDisasm=$(DOTNET_JitDisasm) DOTNET_JitDisasmDiffable=$(DOTNET_JitDisasmDiffable) DOTNET_JitDisasmOnlyOptimized=$(DOTNET_JitDisasmOnlyOptimized) \
		./$(TARGET) $(COUNT) $(INPUT)

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) 1 $(INPUT)

valgrind: $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 $(INPUT)

clean:
	rm -rf bin obj

.PHONY: all clean run measure mem valgrind
