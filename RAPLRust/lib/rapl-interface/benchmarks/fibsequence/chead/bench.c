#include <stdio.h>
#include <stdlib.h>

void start_rapl();
void stop_rapl();

// test method (our own implementation)
unsigned int fibb(unsigned int a){
    if (a <= 1){
        return a;
    }
    return fibb(a-1) + fibb(a-2);
}

int main(int argc, char *argv[]) {
    unsigned int fibParam = atoi(argv[2]);
    int count = atoi(argv[1]);

    for (int i = 0; i < count; i++) {
        start_rapl();
        unsigned int result = fibb(fibParam);
        stop_rapl();

        // stopping compiler optimization
        if (result < 42){
            printf("%u\n", result);
        }
    }
    return 0;
}
