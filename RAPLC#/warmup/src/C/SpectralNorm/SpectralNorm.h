#ifndef SPECTRAL_NORM_H
#define SPECTRAL_NORM_H
#define _GNU_SOURCE
#define false 0
#define true  1

/* define SIMD data type. 2 doubles encapsulated in one XMM register */
typedef double v2dt __attribute__((vector_size(16)));
static const v2dt v1 = {1.0, 1.0};

/* parameter for evaluate functions */
struct Param
{
    double* u;          /* source vector */
    double* tmp;        /* temporary */
    double* v;          /* destination vector */

    int N;              /* source/destination vector length */
    int N2;             /* = N/2 */

    int r_begin;        /* working range of each thread */
    int r_end;
};

int SpectralNorm(int N);
#endif