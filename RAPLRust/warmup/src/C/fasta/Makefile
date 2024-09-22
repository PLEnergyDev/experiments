CC=gcc

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native -std=c99 -mfpmath=sse -msse3 -fopenmp 
LIB_FLAGS=-L../../rapl-interface/target/release -lrapl_lib -Wl,-rpath=../../rapl-interface/target/release
INCLUDE_FLAGS=

CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS) $(INCLUDE_FLAGS)

TARGET=main
SRC=$(TARGET).c

COUNT=20
INPUT=25000000

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
