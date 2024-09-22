CC=gcc

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native -fopenmp -std=c99
LIB_FLAGS=-L../../rapl-interface/target/release -lrapl_lib -Wl,-rpath=../../rapl-interface/target/release
INCLUDE_FLAGS=-IInclude

CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS) $(INCLUDE_FLAGS)

TARGET=main
SRC=$(TARGET).c

COUNT=20

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) 1 < ../../knucleotide-input25000000.txt

measure: $(TARGET)
	modprobe msr
	./$(TARGET) $(COUNT) < ../../knucleotide-input25000000.txt

mem: $(TARGET)
	time -v ./$(TARGET) 1 < ../../knucleotide-input25000000.txt

clean:
	rm -f $(TARGET)

.PHONY: all clean
