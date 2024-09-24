JAVAC=javac
JAVA=java

CLASS=fasta
SRC=$(CLASS).java

RAPL=../../RAPL/main
INPUT=25000000

all: $(CLASS)

$(CLASS): $(SRC)
	$(JAVAC) $(SRC)

run: $(CLASS)
	$(JAVA) $(CLASS) $(INPUT)

measure: $(CLASS)
	modprobe msr
	$(RAPL) "$(JAVA) $(CLASS) $(INPUT)" Java fasta

mem: $(CLASS)
	time -v $(JAVA) $(CLASS) $(INPUT)

valgrind: $(CLASS)
	valgrind --tool=massif --stacks=yes $(JAVA) $(CLASS) $(INPUT)

clean:
	rm -f *.class

.PHONY: all clean run measure mem valgrind
