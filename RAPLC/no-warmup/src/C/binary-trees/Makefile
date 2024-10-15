CC=gcc

OPT_FLAGS=-pipe -Wall -O3 -fomit-frame-pointer -march=native -fopenmp
DEFINES=-D_FILE_OFFSET_BITS=64
INCLUDE_FLAGS=-I/usr/include/apr-1.0
LIB_FLAGS=-lapr-1 -lgomp -lm
CFLAGS=$(OPT_FLAGS) $(DEFINES) $(INCLUDE_FLAGS)

TARGET=main
SRC=$(TARGET).c

RAPL_DIR=../../RAPL
RAPL=$(RAPL_DIR)/main
INPUT=21

$(RAPL):
	@echo "Building RAPL interface..."
	@cd $(RAPL_DIR) && make

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS) $(LIB_FLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) $(INPUT)

measure: $(TARGET) $(RAPL)
	modprobe msr
	$(RAPL) "./$(TARGET) $(INPUT)" C binary-trees

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
