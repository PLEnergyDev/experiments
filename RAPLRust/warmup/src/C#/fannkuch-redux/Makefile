CC=dotnet
CFLAGS=-c Release --no-restore --no-self-contained

TARGET=bin/Release/net8.0/fannkuch-redux
SRC=Program.cs

COUNT=20
INPUT=12

$(TARGET): $(SRC)
	$(CC) restore
	$(CC) build $(CFLAGS)

run: $(TARGET)
	./$(TARGET) 1 $(INPUT)

measure: $(TARGET)
	modprobe msr
	./$(TARGET) $(COUNT) $(INPUT)

mem: $(TARGET)
	time -v ./$(TARGET) 1 $(INPUT)

clean:
	rm -rf bin obj

.PHONY: all clean
