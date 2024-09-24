CC=g++

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native -std=c++14
LIB_FLAGS=-Wl,--no-as-needed -lpthread
CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS)

TARGET=main
SRC=$(TARGET).cpp

RAPL=../../RAPL/target/release/RAPL
INPUT=../../knucleotide-input25000000.txt

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) < $(INPUT)

measure: $(TARGET)
	modprobe msr
	$(RAPL) "./$(TARGET) < $(INPUT)"

mem: $(TARGET)
	time -v ./$(TARGET) < $(INPUT)

valgrind: $(TARGET)
	valgrind --tool=massif --stacks=yes ./$(TARGET) < $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
