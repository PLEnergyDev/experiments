CC=dotnet
CFLAGS=-c Release --no-restore --no-self-contained

TARGET=bin/Release/net8.0/pidigits
SRC=Program.cs

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) restore
	$(CC) build $(CFLAGS)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -rf bin obj

.PHONY: all clean
