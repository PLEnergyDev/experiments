#include <iostream>
#include <vector>

struct Matrix {
    int rows, cols;
    std::vector<double> data;

    // Constructor to initialize the matrix and fill data
    Matrix(int rows, int cols) : rows(rows), cols(cols), data(rows * cols) {}

    // Function to access matrix elements
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

int main(int argc, char *argv[]) {
    if (argc < 3) {
        std::cerr << "Usage: " << argv[0] << " <rows> <cols>" << std::endl;
        return 1;
    }

    int rows = std::atoi(argv[1]);
    int cols = std::atoi(argv[2]);
    for (int i = 0; i < 100; i++) {
        double result = matrix_multiplication(rows, cols);
        std::cout << result << std::endl;
    }

    return 0;
}
