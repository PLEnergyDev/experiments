CC=dotnet
CFLAGS=-c Release --no-restore --no-self-contained

TARGET=bin/Release/net8.0/k-nucleotide
SRC=Program.cs

COUNT=20

$(TARGET): $(SRC)
	$(CC) restore
	$(CC) build $(CFLAGS)

run: $(TARGET)
	./$(TARGET) 1 < ../../knucleotide-input25000000.txt

measure: $(TARGET)
	modprobe msr
	./$(TARGET) $(COUNT) < ../../knucleotide-input25000000.txt

mem: $(TARGET)
	time -v ./$(TARGET) 1 < ../../knucleotide-input25000000.txt

clean:
	rm -rf bin obj

.PHONY: all clean
