CC=javac
CFLAGS=-server

TARGET=SpectralNorm
SRC=$(TARGET).java

all: $(TARGET)

$(TARGET): $(SRC)	
	$(CC) $(CFLAGS) $(SRC)

run: $(TARGET)
	java $(TARGET)

clean:
	rm *.class

.PHONY: all clean
