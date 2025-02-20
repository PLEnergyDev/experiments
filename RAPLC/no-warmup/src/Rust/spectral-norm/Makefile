CC=cargo

CFLAGS=--release

TARGET=target/release/main
SRC=src/main.rs

RAPL_DIR=../../RAPL
RAPL=$(RAPL_DIR)/main
INPUT=5500

$(RAPL):
	@echo "Building RAPL interface..."
	@cd $(RAPL_DIR) && make

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) build $(CFLAGS)

run: $(TARGET) $(RAPL)
	$(TARGET) $(INPUT)

measure: $(TARGET) $(RAPL)
	modprobe msr
	$(RAPL) "$(TARGET) $(INPUT)" Rust spectral-norm

mem: $(TARGET) $(RAPL)
	time -v $(TARGET) $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes $(TARGET) $(INPUT)

clean:
	$(CC) clean

.PHONY: all clean run measure mem valgrind
