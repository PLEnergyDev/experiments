#include <stdlib.h>
#include "PolynomialEvaluation.h"

double* init_cs(int n) {
    double* cs = malloc(n * sizeof(double));
    for (int i = 0; i < n; i++) {
        cs[i] = 1.1 * i;
        if (i % 3 == 0) {
            cs[i] *= -1;
        }
    }

    return cs;
}

double PolynomialEvaluation(int n) {
    double* cs = init_cs(n);
    double res = 0.0;

    for (int i = 0; i < n; i++) {
        res = cs[i] + 5.0 * res;
    }

    free(cs);
    return res;
}
