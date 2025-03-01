#include <stdio.h>
#include <stdlib.h>

void start_rapl();
void stop_rapl();

typedef struct {
    int rows, cols;
    double *data;
} matrix;

void run_benchmark(int rows, int cols) {
    matrix A = {rows, cols, (double *)malloc(rows * cols * sizeof(double))};
    matrix B = {rows, cols, (double *)malloc(rows * cols * sizeof(double))};
    matrix R = {rows, cols, (double *)malloc(rows * cols * sizeof(double))};

    for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
            A.data[r * cols + c] = B.data[r * cols + c] = r + c;
        }
    }

    for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
            double sum = 0.0;
            for (int k = 0; k < cols; k++) {
                sum += A.data[r * cols + k] * B.data[k * cols + c];
            }
            R.data[r * cols + c] = sum;
        }
    }

    double final_sum = R.data[(rows - 1) * cols + (cols - 1)];
    printf("%.0f\n", final_sum);

    free(R.data);
    free(A.data);
    free(B.data);
}

int main(int argc, char *argv[]) {
    int iterations = atoi(argv[1]);
    int rows = atoi(argv[2]);
    int cols = atoi(argv[3]);

    for (int i = 0; i < iterations; i++) {
        start_rapl();
        run_benchmark(rows, cols);
        stop_rapl();
    }
    return 0;
}
