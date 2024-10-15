CC=g++

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native -fopenmp
LIB_FLAGS=-fopenmp -lboost_regex
CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS)

TARGET=main
SRC=$(TARGET).cpp

RAPL_DIR=../../RAPL
RAPL=$(RAPL_DIR)/target/release/RAPL
INPUT=../../regexredux-input5000000.txt

$(RAPL):
	@echo "Building RAPL interface..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) < $(INPUT)

measure: $(TARGET) $(RAPL)
	modprobe msr
	$(RAPL) "./$(TARGET) < $(INPUT)"

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) < $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) < $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
