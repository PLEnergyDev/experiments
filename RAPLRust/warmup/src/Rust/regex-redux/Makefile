CC=cargo
CFLAGS=--release

TARGET=target/release/regex-redux

COUNT=20

$(TARGET): $(SRC)
	$(CC) build $(CFLAGS)

run: $(TARGET)
	./$(TARGET) 1 < ../../regexredux-input5000000.txt

measure: $(TARGET)
	sudo modprobe msr
	./$(TARGET) $(COUNT) < ../../regexredux-input5000000.txt

mem: $(TARGET)
	time -v ./$(TARGET) 1 < ../../regexredux-input5000000.txt

valgrind: $(TARGET)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 < ../../regexredux-input5000000.txt

clean:
	$(CC) clean

.PHONY: all clean
