JAVAC=javac
JAVA=java

CLASS=spectralnorm
SRC=$(CLASS).java

RAPL=../../RAPL/target/release/RAPL
INPUT=5500

all: $(CLASS)

$(CLASS): $(SRC)
	$(JAVAC) $(SRC)

run: $(CLASS)
	$(JAVA) $(CLASS) $(INPUT)

measure: $(CLASS)
	modprobe msr
	$(RAPL) "$(JAVA) $(CLASS) $(INPUT)"

mem: $(CLASS)
	time -v $(JAVA) $(CLASS) $(INPUT)

valgrind: $(CLASS)
	valgrind --tool=massif --stacks=yes $(JAVA) $(CLASS) $(INPUT)

clean:
	rm -f *.class

.PHONY: all clean run measure mem valgrind
