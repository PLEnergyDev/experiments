#include <stdio.h>
#include <stdlib.h>

void start_rapl();
void stop_rapl();

double *initialize(int n) {
  double *cs = malloc(n * sizeof(double));
  for (int i = 0; i < n; i++) {
    cs[i] = 1.1 * i;
    if (i % 3 == 0) {
      cs[i] *= -1;
    }
  }

  return cs;
}

double run_benchmark(double *cs, int n) {
  double res = 0.0;

  for (int i = 0; i < n; i++) {
    res = cs[i] + 5.0 * res;
  }

  return res;
}

void cleanup(double *cs) {
  free(cs);
}

int main(int argc, char *argv[]) {
  int iterations = atoi(argv[1]);
  for (int i = 0; i < iterations; i++) {
    int n = atoi(argv[2]);
    double *cs = initialize(n);
    start_rapl();
    for (int i = 0; i < 20000; i++) {
      double result = run_benchmark(cs, n);
      printf("%f\n", result);
    }
    stop_rapl();
    cleanup(cs);
  }
  return 0;
}
