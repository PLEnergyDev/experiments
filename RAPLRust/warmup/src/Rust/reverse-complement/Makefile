CC=cargo
CFLAGS=--release

TARGET=target/release/reverse-complement

COUNT=20

$(TARGET): $(SRC)
	$(CC) build $(CFLAGS)

run: $(TARGET)
	./$(TARGET) 1 < ../../revcomp-input25000000.txt

measure: $(TARGET)
	sudo modprobe msr
	./$(TARGET) $(COUNT) < ../../revcomp-input25000000.txt

mem: $(TARGET)
	time -v ./$(TARGET) 1 < ../../revcomp-input25000000.txt

valgrind: $(TARGET)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 < ../../revcomp-input25000000.txt

clean:
	$(CC) clean

.PHONY: all clean
