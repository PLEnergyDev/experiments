#include <math.h>
#include "DistributionFunction.h"

double F(double z) {
    double p, zabs = fabs(z), cutoff = 7.071, root2pi = sqrt(2 * M_PI);
    if (zabs > 37)
        p = 0;
    else { // |z| <= 37
        double expntl = exp(zabs * zabs * -.5);
        double pdf = expntl / root2pi ;
        if (zabs < cutoff) // |z| < CUTOFF = 10/sqrt(2)
            p = expntl * ((((((p6 * zabs + p5) * zabs + p4) * zabs + p3) * zabs
                            + p2) * zabs + p1) * zabs + p0) / (((((((q7 * zabs + q6) *
                                                                    zabs + q5) * zabs + q4) * zabs + q3) * zabs + q2) * zabs + q1)
                                                               * zabs + q0);
        else // CUTOFF <= |z| <= 37
            p = pdf / (zabs + 1 / (zabs + 2 / (zabs + 3 / (zabs + 4 / (zabs
                                                                       + .65)))));
    }
    if (z < 0)
        return p;
    else
        return 1-p;
}

void Evaluate(int LoopIterations){
    double result = 0;
    for(int i = 0; i < LoopIterations; i++){
        result += F(-3);
    }
}
