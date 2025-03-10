#include <stdio.h>
#include <stdlib.h>
#include <rapl-interface.h>
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
    int m = atoi(argv[1]);
    while (start_rapl()) {
        run_benchmark(m);
        stop_rapl();
    }
    return 0;
}