#include <stdio.h>
#include <stdlib.h>

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
    int M = atoi(argv[1]);
    for (int i = 0; i < 10; i++) {
        double result = DivisionLoop(M);
        printf("%f\n", result);
    }
    return 0;
}
