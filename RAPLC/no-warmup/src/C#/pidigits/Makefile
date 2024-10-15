CC=dotnet

CFLAGS=-c Release

TARGET=bin/Release/net8.0/pidigits
SRC=Program.cs

RAPL_DIR=../../RAPL
RAPL=$(RAPL_DIR)/main
INPUT=10000

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
	$(RAPL) "$(TARGET) $(INPUT)" C# pidigits

mem: $(TARGET) $(RAPL)
	time -v $(TARGET) $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes $(TARGET) $(INPUT)

clean:
	rm -rf bin obj

.PHONY: all clean run measure mem valgrind
