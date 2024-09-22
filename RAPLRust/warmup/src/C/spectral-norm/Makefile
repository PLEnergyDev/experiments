CC=gcc

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native -fopenmp -mfpmath=sse -msse2
LIB_FLAGS=-lm -L../../rapl-interface/target/release -lrapl_lib -Wl,-rpath=../../rapl-interface/target/release

CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS)

TARGET=main
SRC=$(TARGET).c

COUNT=20
INPUT=5500

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
