SHELL := /bin/bash

CC=gcc

RAPL_FLAGS=-lrapl_interface -Wl,-rpath=/usr/local/lib
CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS) $(RAPL_FLAGS)

TARGET=main
SRC=$(TARGET).c

COUNT?=45
FREQ?=500
CONFIG?=no-warmup

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) $(INPUT)

mem: $(TARGET)
	time -v ./$(TARGET) $(INPUT)

measure: measure_$(CONFIG)

measure_no-warmup: $(TARGET)
	perf stat --all-cpus -I $(FREQ) \
		--append --output perf.txt \
		-e cache-misses,branch-misses,LLC-loads-misses,msr/cpu_thermal_margin/,cpu-clock,cycles \
		-e cstate_core/c3-residency/,cstate_core/c6-residency/,cstate_core/c7-residency/ \
		bash -c 'for i in $$(seq 1 $(COUNT)); do ./$(TARGET) $(INPUT); done'

measure_warmup: $(TARGET)
	perf stat --all-cpus -I $(FREQ) \
		--append --output perf.txt \
		-e cache-misses,branch-misses,LLC-loads-misses,msr/cpu_thermal_margin/,cpu-clock,cycles \
		-e cstate_core/c3-residency/,cstate_core/c6-residency/,cstate_core/c7-residency/ \
		env RAPL_ITERATIONS=$(COUNT) ./$(TARGET) $(INPUT)

valgrind: $(TARGET)
	valgrind --tool=massif --stacks=yes ./$(TARGET) $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all run mem measure measure_no-warmup measure_warmup clean valgrind

.SILENT:
