CC=cargo

CFLAGS=--release
RAPL_DIR=../../rapl-interface
RAPL=$(RAPL_DIR)/target/release/librapl_lib.so

TARGET=target/release/main
SRC=src/main.rs

COUNT=20
INPUT=25000000

$(RAPL):
	@echo "Building rapl-interface with cargo in release mode..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) build $(CFLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) 1 $(INPUT)

measure: $(TARGET) $(RAPL)
	modprobe msr
	./$(TARGET) $(COUNT) $(INPUT)

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) 1 $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 $(INPUT)

clean:
	$(CC) clean

.PHONY: all clean run measure mem valgrind
