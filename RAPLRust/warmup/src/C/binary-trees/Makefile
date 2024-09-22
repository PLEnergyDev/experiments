CC=gcc

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native -fopenmp
LIB_FLAGS=-lapr-1 -lgmp -lm -L../../rapl-interface/target/release -lrapl_lib -Wl,-rpath=../../rapl-interface/target/release
INCLUDE_FLAGS=-I/usr/include/apr-1.0 -D_FILE_OFFSET_BITS=64

CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS) $(INCLUDE_FLAGS)

TARGET=main
SRC=$(TARGET).c

COUNT=20
INPUT=21

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
