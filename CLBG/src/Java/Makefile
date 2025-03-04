SHELL := /bin/bash

JAVAC=javac
JAVA=java

CFLAGS=--enable-preview --release 21
RFLAGS=--enable-preview --enable-native-access=ALL-UNNAMED

CLASS=program
SRC=$(CLASS).java

all: $(CLASS)

$(CLASS): $(SRC)
	$(JAVAC) $(CFLAGS) $(SRC)

run: $(CLASS)
	env LD_LIBRARY_PATH=/usr/local/lib \
	$(JAVA) $(RFLAGS) $(CLASS) $(INPUT)

mem: $(CLASS)
	env LD_LIBRARY_PATH=/usr/local/lib \
	time -v $(JAVA) $(RFLAGS) $(CLASS) $(INPUT)

measure: $(CLASS)
	env LD_LIBRARY_PATH=/usr/local/lib \
	$(JAVA) $(RFLAGS) $(CLASS) $(INPUT)

valgrind:
	env LD_LIBRARY_PATH=/usr/local/lib \
	valgrind --tool=massif --stacks=yes $(JAVA) $(RFLAGS) $(CLASS) $(INPUT)

clean:
	rm -f *.class

.PHONY: all run mem measure measure_no-warmup measure_warmup clean valgrind

.SILENT:
