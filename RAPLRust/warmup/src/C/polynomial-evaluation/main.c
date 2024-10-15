#include <stdio.h>
#include <stdlib.h>

void start_rapl();
void stop_rapl();

////////////////////////////////////////////////////////////////////////////////////////
double *init_cs(int n) {
  double *cs = malloc(n * sizeof(double));
  for (int i = 0; i < n; i++) {
    cs[i] = 1.1 * i;
    if (i % 3 == 0) {
      cs[i] *= -1;
    }
  }

  return cs;
}

double PolynomialEvaluation(int n) {
  double *cs = init_cs(n);
  double res = 0.0;

  for (int i = 0; i < n; i++) {
    res = cs[i] + 5.0 * res;
  }

  free(cs);
  return res;
}
////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char *argv[]) {
  int count = atoi(argv[1]);
  int n = atoi(argv[2]);
  for (int i = 0; i < count; i++) {
    start_rapl();
    for (int i = 0; i < 1000; i++) {
      double result = PolynomialEvaluation(n);
      printf("%f\n", result);
    }
    stop_rapl();
  }
  return 0;
}