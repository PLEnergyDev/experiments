CC=dotnet
CFLAGS=-c Release --no-restore --no-self-contained

TARGET=bin/Release/net8.0/n-body
SRC=Program.cs

COUNT=20
INPUT=50000000

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
