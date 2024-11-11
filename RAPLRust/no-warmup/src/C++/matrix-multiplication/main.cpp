#include <iostream>
#include <threads.h>
#include <vector>

extern "C" {
    void start_rapl();
    void stop_rapl();
}

struct Matrix {
    int rows, cols;
    std::vector<double> data;

    Matrix(int rows, int cols) : rows(rows), cols(cols), data(rows * cols) {}

    double& at(int row, int col) {
        return data[row * cols + col];
    }
};

Matrix init_matrix(int rows, int cols) {
    Matrix m(rows, cols);
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            m.at(i, j) = i + j;
        }
    }
    return m;
}

double matrix_multiplication(int rows, int cols) {
    Matrix R(rows, cols);
    Matrix A = init_matrix(rows, cols);
    Matrix B = init_matrix(rows, cols);

    double sum = 0.0;
    for (int r = 0; r < R.rows; r++) {
        for (int c = 0; c < R.cols; c++) {
            sum = 0.0;
            for (int k = 0; k < A.cols; k++) {
                sum += A.at(r, k) * B.at(k, c);
            }
            R.at(r, c) = sum;
        }
    }

    return sum;
}

int rows;
int cols;

void initialize() {
}

void run_benchmark() {
    for (int i = 0; i < 100; i++) {
        double result = matrix_multiplication(rows, cols);
        std::cout << result << std::endl;
    }
}

void cleanup() {
}

int main(int argc, char *argv[]) {
    int iterations = atoi(argv[1]);
    rows = std::atoi(argv[2]);
    cols = std::atoi(argv[3]);

    for (int i = 0; i < iterations; i++) {
        initialize();
        start_rapl();
        run_benchmark();
        stop_rapl();
        cleanup();
    }

    return 0;
}
