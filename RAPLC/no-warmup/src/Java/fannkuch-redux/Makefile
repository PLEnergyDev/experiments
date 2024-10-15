JAVAC=javac
JAVA=java

CFLAGS=--enable-preview --release 21
RFLAGS=--enable-preview --enable-native-access=ALL-UNNAMED

CLASS=fannkuchredux
SRC=$(CLASS).java

RAPL_DIR=../../RAPL
RAPL=$(RAPL_DIR)/main
INPUT=12

$(RAPL):
	@echo "Building RAPL interface..."
	@cd $(RAPL_DIR) && make

all: $(RAPL) $(CLASS)

$(CLASS): $(SRC) $(RAPL)
	$(JAVAC) $(CFLAGS) $(SRC)

run: $(CLASS) $(RAPL)
	$(JAVA) $(RFLAGS) $(CLASS) $(INPUT)

measure: $(CLASS) $(RAPL)
	modprobe msr
	$(RAPL) "$(JAVA) $(RFLAGS) $(CLASS) $(INPUT)" Java fannkuch-redux

mem: $(CLASS) $(RAPL)
	time -v $(JAVA) $(RFLAGS) $(CLASS) $(INPUT)

valgrind: $(CLASS) $(RAPL)
	valgrind --tool=massif --stacks=yes $(JAVA) $(RFLAGS) $(CLASS) $(INPUT)

clean:
	rm -f *.class

.PHONY: all clean run measure mem valgrind
