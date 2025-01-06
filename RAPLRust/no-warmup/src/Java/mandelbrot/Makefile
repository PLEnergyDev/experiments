SHELL := /bin/bash

JAVAC=javac
JAVA=java

CFLAGS=--enable-preview --release 21
RFLAGS=--enable-preview --enable-native-access=ALL-UNNAMED

CLASS=mandelbrot
SRC=$(CLASS).java

RAPL_DIR=../../rapl-interface
RAPL=$(RAPL_DIR)/target/release/librapl_lib.so

COUNT=45
CACHE_MEASURE_FREQ_MS=500
INPUT=16000

$(RAPL):
	@echo "Building rapl-interface with cargo in release mode..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(CLASS)

$(CLASS): $(SRC) $(RAPL)
	$(JAVAC) $(CFLAGS) $(SRC)

run: $(CLASS) $(RAPL)
	$(JAVA) $(RFLAGS) $(CLASS) 1 $(INPUT)

measure: $(CLASS) $(RAPL)
	perf stat --all-cpus -I $(CACHE_MEASURE_FREQ_MS) \
		--append --output cache.txt \
		-e cache-misses,cache-references,LLC-load-misses,LLC-loads \
		bash -c 'for i in $$(seq 1 $(COUNT)); do \
			$(JAVA) $(RFLAGS) $(CLASS) 1 $(INPUT); \
		done'

mem: $(CLASS) $(RAPL)
	time -v $(JAVA) $(RFLAGS) $(CLASS) 1 $(INPUT)

valgrind: $(RAPL)
	valgrind --tool=massif --stacks=yes $(JAVA) $(RFLAGS) $(CLASS) 1 $(INPUT)

clean:
	rm -f *.class

.PHONY: all clean run measure mem valgrind
