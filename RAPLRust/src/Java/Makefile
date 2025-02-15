SHELL := /bin/bash

JAVAC=javac
JAVA=java

CFLAGS=--enable-preview --release 21
RFLAGS=--enable-preview --enable-native-access=ALL-UNNAMED

CLASS=program
SRC=$(CLASS).java

RAPL_DIR=../../../lib/rapl-interface
RAPL=$(RAPL_DIR)/target/release/librapl_lib.so

COUNT?=45
CACHE_MEASURE_FREQ_MS?=500

MODE?=no-warmup

$(RAPL):
	@echo "Building rapl-interface with cargo in release mode..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(CLASS)

$(CLASS): $(SRC) $(RAPL)
	$(JAVAC) $(CFLAGS) $(SRC)

run: $(CLASS) $(RAPL)
	$(JAVA) $(RFLAGS) $(CLASS) 1 $(INPUT)

mem: $(CLASS) $(RAPL)
	time -v $(JAVA) $(RFLAGS) $(CLASS) 1 $(INPUT)

valgrind: $(RAPL)
	valgrind --tool=massif --stacks=yes $(JAVA) $(RFLAGS) $(CLASS) 1 $(INPUT)

clean:
	rm -f *.class

.PHONY: all clean run measure mem valgrind

include ../$(MODE).mk
