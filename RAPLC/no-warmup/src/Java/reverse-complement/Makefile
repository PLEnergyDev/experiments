JAVAC=javac
JAVA=java

CLASS=revcomp
SRC=$(CLASS).java

RAPL=../../RAPL/main
INPUT=../../revcomp-input25000000.txt

all: $(CLASS)

$(CLASS): $(SRC)
	$(JAVAC) $(SRC)

run: $(CLASS)
	$(JAVA) $(LIB_FLAGS) $(CLASS) < $(INPUT)

measure: $(CLASS)
	modprobe msr
	$(RAPL) "$(JAVA) $(LIB_FLAGS) $(CLASS) < $(INPUT)" Java reverse-complement

mem: $(CLASS)
	time -v $(JAVA) $(LIB_FLAGS) $(CLASS) < $(INPUT)

valgrind: $(CLASS)
	valgrind --tool=massif --stacks=yes $(JAVA) $(LIB_FLAGS) $(CLASS) < $(INPUT)

clean:
	rm -f *.class

.PHONY: all clean run measure mem valgrind
