CC=gcc

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native -fopenmp -funroll-loops
LIB_FLAGS=-L../../rapl-interface/target/release -lrapl_lib -Wl,-rpath=../../rapl-interface/target/release
INCLUDE_FLAGS=

CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS) $(INCLUDE_FLAGS)

TARGET=main
SRC=$(TARGET).c

COUNT=20
INPUT=

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) 1 < ../../revcomp-input25000000.txt 

measure: $(TARGET)
	modprobe msr
	./$(TARGET) $(COUNT) < ../../revcomp-input25000000.txt 

mem: $(TARGET)
	time -v ./$(TARGET) 1 < ../../revcomp-input25000000.txt 

clean:
	rm -f $(TARGET)

.PHONY: all clean
