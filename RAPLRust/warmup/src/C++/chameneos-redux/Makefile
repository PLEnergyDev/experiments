CC=g++

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native -fopenmp -std=c++11 -pthread
LIB_FLAGS=-lpthread -L../../rapl-interface/target/release -lrapl_lib -Wl,--no-as-needed,-rpath=../../rapl-interface/target/release
INCLUDE_FLAGS=

CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS) $(INCLUDE_FLAGS)

TARGET=main
SRC=$(TARGET).cpp

COUNT=20
INPUT=6000000

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) 1 $(INPUT) 

measure: $(TARGET)
	modprobe msr
	./$(TARGET) $(COUNT) $(INPUT) 

mem: $(TARGET)
	time -v ./$(TARGET) 1 $(INPUT) 

clean:
	rm -f $(TARGET)

.PHONY: all clean
