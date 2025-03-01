#include <stdio.h>
#include <stdlib.h>

void start_rapl();
void stop_rapl();

void run_benchmark(int m) {
    double sum = 0.0;
    int n = 0;
    while (sum < m) {
        n++;
        sum += 1.0 / n;
    }
    printf("%d\n", n);
}

int main(int argc, char *argv[]) {
    int iterations = atoi(argv[1]);
    int m = atoi(argv[2]);
    for (int i = 0; i < iterations; i++) {
        start_rapl();
        run_benchmark(m);
        stop_rapl();
    }
    return 0;
}
