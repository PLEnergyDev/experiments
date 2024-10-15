CC=gcc

OPT_FLAGS=-pipe -Wall -O3 -fomit-frame-pointer -march=native -pthread
CFLAGS=$(OPT_FLAGS)

TARGET=main
SRC=$(TARGET).c

RAPL_DIR=../../RAPL
RAPL=$(RAPL_DIR)/main
INPUT=1000

$(RAPL):
	@echo "Building RAPL interface..."
	@cd $(RAPL_DIR) && make

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) $(INPUT)

measure: $(RAPL) $(TARGET)
	modprobe msr
	$(RAPL) "./$(TARGET) $(INPUT)" C polynomial-evaluation

valgrind: $(TARGET)
	valgrind --tool=massif --stacks=yes $(TARGET) $(INPUT)

mem: $(TARGET)
	time -v ./$(TARGET) $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
