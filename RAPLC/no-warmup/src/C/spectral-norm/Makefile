CC=gcc

OPT_FLAGS=-pipe -Wall -O3 -fomit-frame-pointer -march=native -fopenmp -mfpmath=sse -msse2
LIB_FLAGS=-lm
CFLAGS=$(OPT_FLAGS)

TARGET=main
SRC=$(TARGET).c

RAPL_DIR=../../RAPL
RAPL=$(RAPL_DIR)/main
INPUT=5500

$(RAPL):
	@echo "Building RAPL interface..."
	@cd $(RAPL_DIR) && make

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS) $(LIB_FLAGS)

run: $(TARGET)
	./$(TARGET) $(INPUT)

measure: $(RAPL) $(TARGET)
	modprobe msr
	$(RAPL) "./$(TARGET) $(INPUT)" C spectral-norm

mem: $(TARGET)
	time -v ./$(TARGET) $(INPUT)

valgrind: $(TARGET)
	valgrind --tool=massif --stacks=yes ./$(TARGET) $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
