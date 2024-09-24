JAVAC=javac
JAVA=java

LIB_FLAGS=-cp .:/usr/local/src/java-libs/fastutil-7.0.12.jar

CLASS=knucleotide
SRC=$(CLASS).java

RAPL=../../RAPL/main
INPUT=../../knucleotide-input25000000.txt

all: $(CLASS)

$(CLASS): $(SRC)
	$(JAVAC) $(LIB_FLAGS) $(SRC)

run: $(CLASS)
	$(JAVA) $(LIB_FLAGS) $(CLASS) < $(INPUT)

measure: $(CLASS)
	modprobe msr
	$(RAPL) "$(JAVA) $(LIB_FLAGS) $(CLASS) < $(INPUT)" Java k-nucleotide

mem: $(CLASS)
	time -v $(JAVA) $(LIB_FLAGS) $(CLASS) < $(INPUT)

valgrind: $(CLASS)
	valgrind --tool=massif --stacks=yes $(JAVA) $(LIB_FLAGS) $(CLASS) < $(INPUT)

clean:
	rm -f *.class

.PHONY: all clean run measure mem valgrind
