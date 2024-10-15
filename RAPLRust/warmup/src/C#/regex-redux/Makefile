CC=dotnet

CFLAGS=-c Release
RAPL_DIR=../../rapl-interface
RAPL=$(RAPL_DIR)/target/release/librapl_lib.so

TARGET=bin/Release/net8.0/regex-redux
SRC=Program.cs

COUNT=20
INPUT=../../regexredux-input5000000.txt

$(RAPL):
	@echo "Building rapl-interface with cargo in release mode..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) build $(CFLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) 1 < $(INPUT)

measure: $(TARGET) $(RAPL)
	modprobe msr
	./$(TARGET) $(COUNT) < $(INPUT)

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) 1 < $(INPUT)

valgrind: $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 < $(INPUT)

clean:
	rm -rf bin obj

.PHONY: all clean run measure mem valgrind
