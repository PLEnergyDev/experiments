CC=dotnet
CFLAGS=-c Release --no-restore --no-self-contained

TARGET=bin/Release/net8.0/reverse-complement
SRC=Program.cs

COUNT=20
INPUT=

$(TARGET): $(SRC)
	$(CC) restore
	$(CC) build $(CFLAGS)

run: $(TARGET)
	./$(TARGET) 1 < ../../revcomp-input25000000.txt

measure: $(TARGET)
	modprobe msr
	./$(TARGET) $(COUNT) < ../../revcomp-input25000000.txt

mem: $(TARGET)
	time -v ./$(TARGET) 1 < ../../revcomp-input25000000.txt

clean:
	rm -rf bin obj

.PHONY: all clean
