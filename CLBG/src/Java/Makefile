SHELL := /bin/bash

JAVAC=javac
JAVA=java

CFLAGS=--enable-preview --release 21
RFLAGS=--enable-preview --enable-native-access=ALL-UNNAMED

CLASS=program
SRC=$(CLASS).java

COUNT?=45
FREQ?=500
CONFIG?=no-warmup

all: $(CLASS)

$(CLASS): $(SRC)
	$(JAVAC) $(CFLAGS) $(SRC)

run: $(CLASS)
	env LD_LIBRARY_PATH=/usr/local/lib \
	$(JAVA) $(RFLAGS) $(CLASS) $(INPUT)

mem: $(CLASS)
	env LD_LIBRARY_PATH=/usr/local/lib \
	time -v $(JAVA) $(RFLAGS) $(CLASS) $(INPUT)

measure: measure_$(CONFIG)

measure_no-warmup: $(CLASS)
	env LD_LIBRARY_PATH=/usr/local/lib \
	perf stat --all-cpus -I $(FREQ) \
		--append --output perf.txt \
		-e cache-misses,branch-misses,LLC-loads-misses,msr/cpu_thermal_margin/,cpu-clock,cycles \
		-e cstate_core/c3-residency/,cstate_core/c6-residency/,cstate_core/c7-residency/ \
		bash -c 'for i in $$(seq 1 $(COUNT)); do $(JAVA) $(RFLAGS) $(CLASS) $(INPUT); done'

measure_warmup: $(CLASS)
	env LD_LIBRARY_PATH=/usr/local/lib \
	perf stat --all-cpus -I $(FREQ) \
		--append --output perf.txt \
		-e cache-misses,branch-misses,LLC-loads-misses,msr/cpu_thermal_margin/,cpu-clock,cycles \
		-e cstate_core/c3-residency/,cstate_core/c6-residency/,cstate_core/c7-residency/ \
		env RAPL_ITERATIONS=$(COUNT) $(JAVA) $(RFLAGS) $(CLASS) $(INPUT)

valgrind:
	env LD_LIBRARY_PATH=/usr/local/lib \
	valgrind --tool=massif --stacks=yes $(JAVA) $(RFLAGS) $(CLASS) $(INPUT)

clean:
	rm -f *.class

.PHONY: all run mem measure measure_no-warmup measure_warmup clean valgrind

.SILENT:
