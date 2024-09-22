CC=node
CFLAGS=--no-deprecation

SRC=main.js

COUNT=20
INPUT=5500

run: setup
	$(CC) $(CFLAGS) $(SRC) 1 $(INPUT)

measure: setup
	modprobe msr
	$(CC) $(CFLAGS) $(SRC) $(COUNT) $(INPUT)

mem: setup
	time -v $(CC) $(CFLAGS) $(SRC) 1 $(INPUT)

setup:
	npm install koffi

clean:
	rm -rf node_modules
	rm -f package-lock.json
