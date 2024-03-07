CC=/usr/bin/gcc
CFLAGS=-Wall -O3

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
