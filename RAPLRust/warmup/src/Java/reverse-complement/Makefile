CC=javac
CFLAGS=--enable-preview --release 21 -d .

TARGET=revcomp
SRC=revcomp.java

COUNT=20
INPUT=

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC)

run: $(TARGET)
	java --enable-preview $(TARGET) 1 < ../../revcomp-input25000000.txt

measure: $(TARGET)
	modprobe msr
	java --enable-preview $(TARGET) $(COUNT) < ../../revcomp-input25000000.txt

mem: $(TARGET)
	time -v java --enable-preview $(TARGET) 1 < ../../revcomp-input25000000.txt

clean:
	rm -f *.class

.PHONY: all clean
