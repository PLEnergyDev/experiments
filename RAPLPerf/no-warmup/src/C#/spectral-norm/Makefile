CC=dotnet

OPT_FLAGS=-c Release

TARGET=bin/Release/net8.0/program
SRC=Program.cs

RAPL=../../RAPL/target/release/RAPL

INPUT=5500

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) build $(OPT_FLAGS)

run: $(TARGET)
	$(TARGET) $(INPUT)

measure: $(TARGET)
	modprobe msr
	$(RAPL) "$(TARGET) $(INPUT)"

mem: $(TARGET)
	time -v $(TARGET) $(INPUT)

valgrind:
	valgrind --tool=massif --stacks=yes $(TARGET) $(INPUT)

clean:
	rm -rf bin obj

.PHONY: all clean run measure mem valgrind
