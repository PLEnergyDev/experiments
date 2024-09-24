CC=cargo

OPT_FLAGS=--release

TARGET=target/release/main
SRC=src/main.rs

RAPL=../../RAPL/target/release/RAPL
INPUT=25000000

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
	$(CC) clean

.PHONY: all clean run measure mem valgrind
