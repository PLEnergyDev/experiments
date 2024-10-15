CC=dotnet

CFLAGS=-c Release

RAPL_DIR=../../RAPL
RAPL=$(RAPL_DIR)/target/release/RAPL

TARGET=bin/Release/net8.0/binary-trees
SRC=Program.cs

INPUT=21

$(RAPL):
	@echo "Building RAPL interface..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) build $(CFLAGS)

run: $(TARGET) $(RAPL)
	$(TARGET) $(INPUT)

measure: $(TARGET) $(RAPL)
	modprobe msr
	$(RAPL) "$(TARGET) $(INPUT)"

mem: $(TARGET) $(RAPL)
	time -v $(TARGET) $(INPUT)

valgrind: $(RAPL)
	valgrind --tool=massif --stacks=yes $(TARGET) $(INPUT)

clean:
	rm -rf bin obj

.PHONY: all clean run measure mem valgrind
