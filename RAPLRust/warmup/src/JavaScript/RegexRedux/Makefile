CC=node
CFLAGS=--no-deprecation

SRC=main.js

COUNT=20
INPUT=

run: setup
	$(CC) $(CFLAGS) $(SRC) 1 < ../../regexredux-input5000000.txt

measure: setup
	modprobe msr
	$(CC) $(CFLAGS) $(SRC) $(COUNT) < ../../regexredux-input5000000.txt

mem: setup
	time -v $(CC) $(CFLAGS) $(SRC) 1 < ../../regexredux-input5000000.txt

setup:
	npm install koffi

clean:
	rm -rf node_modules
	rm -f package-lock.json
