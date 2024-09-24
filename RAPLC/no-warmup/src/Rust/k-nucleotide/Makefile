CC=cargo

OPT_FLAGS=--release

TARGET=target/release/main
SRC=src/main.rs

RAPL=../../RAPL/main
INPUT=../../knucleotide-input25000000.txt

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) build $(OPT_FLAGS)

run: $(TARGET)
	$(TARGET) < $(INPUT)

measure: $(TARGET)
	modprobe msr
	$(RAPL) "$(TARGET) < $(INPUT)" Rust k-nucleotide

mem: $(TARGET)
	time -v $(TARGET) < $(INPUT)

valgrind:
	valgrind --tool=massif --stacks=yes $(TARGET) < $(INPUT)

clean:
	$(CC) clean

.PHONY: all clean run measure mem valgrind
