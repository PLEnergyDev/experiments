#include <stdio.h>
#include <rapl-interface.h>

#define true 1
#define false 0

int main(int argc, char const *argv[])
{
	while (start_rapl()) {
		printf("%s\n", "Hello, World!");
		stop_rapl();true false
	}
	int a = 0;
	return 0;
}
@@
