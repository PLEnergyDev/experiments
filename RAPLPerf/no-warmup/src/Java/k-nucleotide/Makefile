JAVAC=javac
JAVA=java

CFLAGS=--enable-preview --release 21 -cp .:/usr/local/src/java-libs/fastutil-7.0.12.jar
RFLAGS=--enable-preview --enable-native-access=ALL-UNNAMED -cp .:/usr/local/src/java-libs/fastutil-7.0.12.jar

CLASS=knucleotide
SRC=$(CLASS).java

RAPL_DIR=../../RAPL
RAPL=$(RAPL_DIR)/target/release/RAPL
INPUT=../../knucleotide-input25000000.txt

$(RAPL):
	@echo "Building RAPL interface..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(CLASS)

$(CLASS): $(SRC) $(RAPL)
	$(JAVAC) $(CFLAGS) $(SRC)

run: $(CLASS) $(RAPL)
	$(JAVA) $(RFLAGS) $(CLASS) < $(INPUT)

measure: $(CLASS) $(RAPL)
	modprobe msr
	$(RAPL) "$(JAVA) $(RFLAGS) $(CLASS) < $(INPUT)" Java k-nucleotide

mem: $(CLASS) $(RAPL)
	time -v $(JAVA) $(RFLAGS) $(CLASS) < $(INPUT)

valgrind: $(CLASS) $(RAPL)
	valgrind --tool=massif --stacks=yes $(JAVA) $(RFLAGS) $(CLASS) < $(INPUT)

clean:
	rm -f *.class

.PHONY: all clean run measure mem valgrind
