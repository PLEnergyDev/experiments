CC=g++

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native -std=c++11 -mtune=native -mfpmath=sse -msse2
LIB_FLAGS=-pthread
CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS)

TARGET=main
SRC=$(TARGET).cpp

RAPL=../../RAPL/main
INPUT=../../revcomp-input25000000.txt

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) < $(INPUT)

measure: $(TARGET)
	modprobe msr
	$(RAPL) "./$(TARGET) < $(INPUT)" C++ reverse-complement

mem: $(TARGET)
	time -v ./$(TARGET) < $(INPUT)

valgrind: $(TARGET)
	valgrind --tool=massif --stacks=yes ./$(TARGET) < $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
