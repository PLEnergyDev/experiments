CC=dotnet

CFLAGS=-c Release

TARGET=bin/Release/net8.0/regex-redux
SRC=Program.cs

RAPL=../../RAPL/main
INPUT=../../regexredux-input5000000.txt

$(RAPL):
	@echo "Building RAPL interface..."
	@cd $(RAPL_DIR) && make

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) build $(CFLAGS)

run: $(TARGET) $(RAPL)
	$(TARGET) < $(INPUT)

measure: $(TARGET) $(RAPL)
	modprobe msr
	$(RAPL) "$(TARGET) < $(INPUT)" C# regex-redux

mem: $(TARGET) $(RAPL)
	time -v $(TARGET) < $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes $(TARGET) < $(INPUT)

clean:
	rm -rf bin obj

.PHONY: all clean run measure mem valgrind
