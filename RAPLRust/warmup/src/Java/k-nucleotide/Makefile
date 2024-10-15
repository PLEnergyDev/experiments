JAVAC=javac
JAVA=java

CFLAGS=--enable-preview --release 21 -cp .:/usr/local/src/java-libs/fastutil-7.0.12.jar
RFLAGS=--enable-preview --enable-native-access=ALL-UNNAMED -cp .:/usr/local/src/java-libs/fastutil-7.0.12.jar

RAPL_DIR=../../rapl-interface
RAPL=$(RAPL_DIR)/target/release/librapl_lib.so

CLASS=knucleotide
SRC=$(CLASS).java

COUNT=20
INPUT=../../knucleotide-input25000000.txt

$(RAPL):
	@echo "Building rapl-interface with cargo in release mode..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(CLASS)

$(CLASS): $(SRC) $(RAPL)
	$(JAVAC) $(CFLAGS) $(SRC)

run: $(CLASS) $(RAPL)
	$(JAVA) $(RFLAGS) $(CLASS) 1 < $(INPUT)

measure: $(CLASS) $(RAPL)
	modprobe msr
	$(JAVA) $(RFLAGS) $(CLASS) $(COUNT) < $(INPUT)

mem: $(CLASS) $(RAPL)
	time -v $(JAVA) $(RFLAGS) $(CLASS) 1 < $(INPUT)

valgrind: $(RAPL)
	valgrind --tool=massif --stacks=yes $(JAVA) $(RFLAGS) $(CLASS) 1 < $(INPUT)

clean:
	rm -f *.class

.PHONY: all clean run measure mem valgrind
