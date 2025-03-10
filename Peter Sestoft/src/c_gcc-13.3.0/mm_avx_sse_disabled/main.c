#include <stdio.h>
#include <stdlib.h>
#include <rapl-interface.h>

void run_benchmark(int rows, int cols) {
    double *A = (double *)malloc(rows * cols * sizeof(double));
    double *B = (double *)malloc(rows * cols * sizeof(double));
    double *R = (double *)malloc(rows * cols * sizeof(double));

    for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
            A[r * cols + c] = B[r * cols + c] = r + c;
        }
    }

    for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
            double sum = 0.0;
            for (int k = 0; k < cols; k++) {
                sum += A[r * cols + k] * B[k * cols + c];
            }
            R[r * cols + c] = sum;
        }
    }

    double final_sum = R[(rows - 1) * cols + (cols - 1)];
    printf("%.0f\n", final_sum);

    free(R);
    free(A);
    free(B);
}

int main(int argc, char *argv[]) {
    int rows = atoi(argv[1]);
    int cols = atoi(argv[2]);

    while (start_rapl()) {
        run_benchmark(rows, cols);
        stop_rapl();
    }
    return 0;
}
