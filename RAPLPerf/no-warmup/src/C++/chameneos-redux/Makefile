CC=g++

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native --std=c++11 -pthread
LINK_FLAGS=-Wl,--no-as-needed -lpthread
CFLAGS=$(OPT_FLAGS) $(LINK_FLAGS)

TARGET=main
SRC=$(TARGET).cpp

RAPL=../../RAPL/target/release/RAPL
INPUT=6000000

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) $(INPUT)

measure: $(TARGET)
	modprobe msr
	$(RAPL) "./$(TARGET) $(INPUT)"

mem: $(TARGET)
	time -v ./$(TARGET) $(INPUT)

valgrind: $(TARGET)
	valgrind --tool=massif --stacks=yes ./$(TARGET) $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
