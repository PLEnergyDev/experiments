CC=/usr/bin/gcc
CFLAGS=-pipe -O3 -fomit-frame-pointer -march=ivybridge -mno-fma -fno-finite-math-only -fopenmp

TARGET=main
SRC=$(TARGET).c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all clean