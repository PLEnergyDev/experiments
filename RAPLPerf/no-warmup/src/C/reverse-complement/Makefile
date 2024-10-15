CC=gcc

OPT_FLAGS=-pipe -Wall -O3 -fomit-frame-pointer -march=native -funroll-loops -fopenmp
CFLAGS=$(OPT_FLAGS)

TARGET=main
SRC=$(TARGET).c

RAPL_DIR=../../RAPL
RAPL=$(RAPL_DIR)/target/release/RAPL

INPUT=../../revcomp-input25000000.txt

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

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem
