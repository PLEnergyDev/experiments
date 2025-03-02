#include <stdio.h>
#include <stdlib.h>
#include <immintrin.h>
#include <omp.h>
#include <rapl-interface.h>


typedef struct {
    int rows, cols;
    double *data;
} matrix;

// Function to transpose matrix B for better cache locality
void transpose(matrix *B, matrix *B_T) {
    for (int r = 0; r < B->rows; r++) {
        for (int c = 0; c < B->cols; c++) {
            B_T->data[c * B->rows + r] = B->data[r * B->cols + c];
        }
    }
}

void run_benchmark(matrix *A, matrix *B_T, matrix *R) {
    int rows = A->rows;
    int cols = A->cols;

    // Matrix multiplication with transposed B_T
    #pragma omp parallel for
    for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c += 4) {  // Process 4 elements at a time using AVX
            __m256d sum_vec = _mm256_setzero_pd();
            for (int k = 0; k < cols; k++) {
                __m256d a_vec = _mm256_set1_pd(A->data[r * cols + k]);
                __m256d b_vec = _mm256_loadu_pd(&B_T->data[c * cols + k]);
                sum_vec = _mm256_fmadd_pd(a_vec, b_vec, sum_vec);
            }
            _mm256_storeu_pd(&R->data[r * cols + c], sum_vec);
        }
    }

    printf("%f\n", R->data[(rows - 1) * cols + (cols - 1)]);
}

int main(int argc, char *argv[]) {
    int rows = atoi(argv[1]);
    int cols = atoi(argv[2]);

    // Allocate matrices once and reuse
    matrix A = {rows, cols, (double *)aligned_alloc(32, rows * cols * sizeof(double))};
    matrix B = {rows, cols, (double *)aligned_alloc(32, rows * cols * sizeof(double))};
    matrix B_T = {cols, rows, (double *)aligned_alloc(32, cols * rows * sizeof(double))};
    matrix R = {rows, cols, (double *)aligned_alloc(32, rows * cols * sizeof(double))};

    // Initialize A and B
    for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
            A.data[r * cols + c] = B.data[r * cols + c] = r + c;
        }
    }

    // Transpose B
    transpose(&B, &B_T);

    while (start_rapl()) {
        run_benchmark(&A, &B_T, &R);
        stop_rapl();
    }

    // Free allocated memory
    free(A.data);
    free(B.data);
    free(B_T.data);
    free(R.data);

    return 0;
}
