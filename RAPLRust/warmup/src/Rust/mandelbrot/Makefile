CC=cargo
CFLAGS=--release

TARGET=target/release/mandelbrot

COUNT=20
INPUT=16000

$(TARGET): $(SRC)
	$(CC) build $(CFLAGS)

run: $(TARGET)
	./$(TARGET) 1 $(INPUT)

measure: $(TARGET)
	sudo modprobe msr
	./$(TARGET) $(COUNT) $(INPUT)

mem: $(TARGET)
	time -v ./$(TARGET) 1 $(INPUT)

valgrind: $(TARGET)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 $(INPUT)

clean:
	$(CC) clean

.PHONY: all clean
