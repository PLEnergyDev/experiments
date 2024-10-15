CC=gcc

OPT_FLAGS=-pipe -Wall -O3 -fomit-frame-pointer -march=native -std=c99 -mfpmath=sse -msse3 -fopenmp
CFLAGS=$(OPT_FLAGS)

TARGET=main
SRC=$(TARGET).c

RAPL_DIR=../../RAPL
RAPL=$(RAPL_DIR)/main
INPUT=25000000

$(RAPL):
	@echo "Building RAPL interface..."
	@cd $(RAPL_DIR) && make

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) $(INPUT)

measure: $(TARGET) $(RAPL)
	modprobe msr
	$(RAPL) "./$(TARGET) $(INPUT)" C fasta

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
