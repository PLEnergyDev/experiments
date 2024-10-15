CC=g++

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native -mfpmath=sse -msse3 --std=c++11 -fopenmp
CFLAGS=$(OPT_FLAGS)

TARGET=main
SRC=$(TARGET).cpp

RAPL_DIR=../../RAPL
RAPL=$(RAPL_DIR)/main
INPUT=20

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
	$(RAPL) "./$(TARGET) $(INPUT)" C++ division-loop

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
