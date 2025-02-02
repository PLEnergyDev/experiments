#include <stdio.h>
#include <stdlib.h>

void start_rapl();
void stop_rapl();

void initialize(int *m, char *argv[]) { *m = atoi(argv[2]); }

void run_benchmark(int m) {
    for (int i = 0; i < 10; i++) {
        double sum = 0.0;
        double n = 0;
        while (sum < m) {
            n++;
            sum += 1.0 / n;
        }
        printf("%f\n", n);
    }
}

void cleanup() {}

int main(int argc, char *argv[]) {
    int iterations = atoi(argv[1]);
    for (int i = 0; i < iterations; i++) {
        int m;
        initialize(&m, argv);
        start_rapl();
        run_benchmark(m);
        stop_rapl();
        cleanup();
    }
    return 0;
}
