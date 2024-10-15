CC=gcc

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native -fopenmp -std=c99
LIB_FLAGS=-L$(RAPL_DIR)/target/release -lrapl_lib -Wl,-rpath=$(RAPL_DIR)/target/release
INCLUDE_FLAGS=-IInclude
CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS) $(INCLUDE_FLAGS)

TARGET=main
SRC=$(TARGET).c

RAPL_DIR=../../rapl-interface
RAPL=$(RAPL_DIR)/target/release/librapl_lib.so
COUNT=20
INPUT=../../knucleotide-input25000000.txt

# Ensure RAPL is built before anything else
$(RAPL):
	@echo "Building rapl-interface with cargo in release mode..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) 1 < $(INPUT)

measure: $(TARGET) $(RAPL)
	modprobe msr
	./$(TARGET) $(COUNT) < $(INPUT)

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) 1 < $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 < $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
