#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void start_rapl();
void stop_rapl();

int main(int argc, char *argv[]) {
    int count = atoi(argv[1]);
    int sleep_time = atoi(argv[2]);

    for (int i = 0; i < count; i++) {
        start_rapl();
        sleep(sleep_time);
        stop_rapl();
    }

    return 0;
}
