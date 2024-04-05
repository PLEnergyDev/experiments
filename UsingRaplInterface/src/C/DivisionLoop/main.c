#include <stdio.h>
#include <stdlib.h>

void start_rapl();
void stop_rapl();

////////////////////////////////////////////////////////////////////////////////////////
double DivisionLoop(int M) {
    double sum = 0.0;
    int n = 0;
    while (sum < M) {
        n++;
        sum += 1.0 / n;
    }
    return n;
}
////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char *argv[]) {
    int count = atoi(argv[1]);
    int M = atoi(argv[2]);

    for (int i = 0; i < count; i++) {
        start_rapl();
        double result = DivisionLoop(M);
        stop_rapl();

        printf("%f\n", result);
    }
    return 0;
}
