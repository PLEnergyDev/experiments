#include <stdio.h>
#include <stdlib.h>

void start_rapl();
void stop_rapl();

typedef struct {
  int rows, cols;
  double *data;
} matrix;

matrix init_matrix(int rows, int cols) {
  matrix m = {rows, cols, (double *)malloc(rows * cols * sizeof(double))};
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      m.data[rows * i + j] = i + j;
    }
  }
  return m;
}

void free_matrix(matrix *m) {
  free(m->data);
  m->data = NULL;
}

double run_benchmark(matrix A, matrix B, int rows, int cols) {
  matrix R = {rows, cols, (double *)malloc(rows * cols * sizeof(double))};
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
  free(R.data);
  return sum;
}

void cleanup(matrix *A, matrix *B) {
  free_matrix(A);
  free_matrix(B);
}

int main(int argc, char *argv[]) {
  int iterations = atoi(argv[1]);
  for (int i = 0; i < iterations; i++) {
    int rows = atoi(argv[2]);
    int cols = atoi(argv[3]);
    matrix A = init_matrix(rows, cols);
    matrix B = init_matrix(rows, cols);
    start_rapl();
    for (int j = 0; j < 100; j++) {
      double result = run_benchmark(A, B, rows, cols);
      printf("%f\n", result);
    }
    stop_rapl();
    cleanup(&A, &B);
  }
  return 0;
}
