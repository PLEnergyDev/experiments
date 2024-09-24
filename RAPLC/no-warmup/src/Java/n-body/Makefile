JAVAC=javac
JAVA=java

CLASS=nbody
SRC=$(CLASS).java

RAPL=../../RAPL/main
INPUT=50000000

all: $(CLASS)

$(CLASS): $(SRC)
	$(JAVAC) $(SRC)

run: $(CLASS)
	$(JAVA) $(CLASS) $(INPUT)

measure: $(CLASS)
	modprobe msr
	$(RAPL) "$(JAVA) $(CLASS) $(INPUT)" Java n-body

mem: $(CLASS)
	time -v $(JAVA) $(CLASS) $(INPUT)

valgrind: $(CLASS)
	valgrind --tool=massif --stacks=yes $(JAVA) $(CLASS) $(INPUT)

clean:
	rm -f *.class

.PHONY: all clean run measure mem valgrind
