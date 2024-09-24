CC=cargo

OPT_FLAGS=--release

TARGET=target/release/main
SRC=src/main.rs

RAPL=../../RAPL/main
INPUT=16000

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) build $(OPT_FLAGS)

run: $(TARGET)
	$(TARGET) $(INPUT)

measure: $(TARGET)
	modprobe msr
	$(RAPL) "$(TARGET) $(INPUT)" Rust mandelbrot

mem: $(TARGET)
	time -v $(TARGET) $(INPUT)

valgrind:
	valgrind --tool=massif --stacks=yes $(TARGET) $(INPUT)

clean:
	$(CC) clean

.PHONY: all clean run measure mem valgrind
