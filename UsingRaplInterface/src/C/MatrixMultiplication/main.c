#include <stdio.h>
#include <stdlib.h>

void start_rapl();
void stop_rapl();

////////////////////////////////////////////////////////////////////////////////////////
typedef struct {
    int rows, cols;
    double *data;
} matrix;

matrix init_matrix(int rows, int cols) {
    matrix m = {
        rows, cols,
        (double *)malloc(rows * cols * sizeof(double))
    };
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            m.data[rows * i + j] = i + j;
        }
    }
    return m;
}

double MatrixMultiplication(int rows, int cols) {
    matrix R = {
        rows, cols,
        (double *)malloc(rows * cols * sizeof(double))
    };
    matrix A = init_matrix(rows, cols), B = init_matrix(rows, cols);

    double sum;
    for (int r = 0; r < R.rows; r++) {
        for (int c = 0; c < R.cols; c++) {
            sum = 0.0;
            for (int k = 0; k < A.cols; k++) {
                sum += A.data[r * A.cols + k] * B.data[k * B.cols + c];
            }
            R.data[r * R.cols + c] = sum;
        }
    }

    free(A.data);
    free(B.data);
    free(R.data);
    return sum;
}
////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char *argv[]) {
    int count = atoi(argv[1]);
    int rows = atoi(argv[2]);
    int cols = atoi(argv[3]);

    for (int i = 0; i < count; i++) {
        start_rapl();
        double result = MatrixMultiplication(rows, cols);
        stop_rapl();

        printf("%f\n", result);
    }
    return 0;
}
