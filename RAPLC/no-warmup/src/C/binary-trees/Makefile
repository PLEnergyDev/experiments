CC=gcc

OPT_FLAGS=-pipe -Wall -O3 -fomit-frame-pointer -march=native -fopenmp
DEFINES=-D_FILE_OFFSET_BITS=64
INCLUDE_FLAGS=-I/usr/include/apr-1.0
LIB_FLAGS=-lapr-1 -lgomp -lm

CFLAGS=$(OPT_FLAGS) $(DEFINES) $(INCLUDE_FLAGS)

TARGET=main
SRC=$(TARGET).c

RAPL=../../RAPL/main
INPUT=21

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS) $(LIB_FLAGS)

run: $(TARGET)
	./$(TARGET) $(INPUT)

measure: $(TARGET)
	modprobe msr
	$(RAPL) "./$(TARGET) $(INPUT)" C binary-trees

mem: $(TARGET)
	time -v ./$(TARGET) $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem
