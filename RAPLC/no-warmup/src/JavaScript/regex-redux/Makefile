compile:
	cp -L regexredux.node-2.node regexredux.node-2.js
measure:
	sudo modprobe msr
	sudo ../../RAPL/main "node --no-deprecation regexredux.node-2.js 0 < ../../regexredux-input5000000.txt" JavaScript regex-redux

run:
	node --no-deprecation regexredux.node-2.js 0 < ../../regexredux-input5000000.txt

mem:
	time -v node --no-deprecation regexredux.node-2.js 0 < ../../regexredux-input5000000.txt

valgrind:
	valgrind --tool=massif --stacks=yes node --no-deprecation regexredux.node-2.js 0 < ../../regexredux-input5000000.txt
