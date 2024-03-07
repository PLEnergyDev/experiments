#ifndef MATRIX_MULTIPLICATION_H
#define MATRIX_MULTIPLICATION_H

typedef struct {
	int rows, cols;
	double *data;
} matrix;

double MatrixMultiplication(int rows, int cols);

#endif
