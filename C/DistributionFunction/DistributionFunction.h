#include <math.h>
#ifndef C_DISTRIBUTIONFUNCTION_H
#define C_DISTRIBUTIONFUNCTION_H
static double p0 = 220.2068679123761,
        p1 = 221.2135961699311,
        p2 = 112.0792914978709, 
        p3 = 33.912866078383,
        p4 = 6.37396220353165,
        p5 = .7003830644436881,
        p6 = .03526249659989109, 
        q0 = 440.4137358247522,
        q1 = 793.8265125199484,
        q2 = 637.3336333788311,
        q3 = 296.5642487796737,
        q4 = 86.78073220294608,
        q5 = 16.06417757920695,
        q6 = 1.755667163182642,
        q7 = .08838834764831844;

double F(double z);
void Evaluate(int LoopIterations);

#endif //C_DISTRIBUTIONFUNCTION_H