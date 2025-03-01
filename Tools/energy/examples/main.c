#include <stdio.h>
#include <rapl-interface.h>

int main(int argc, char const *argv[])
{
	while (start_rapl()) {
		printf("%s\n", "Hello, World!");
		stop_rapl();
	}

	return 0;
}
