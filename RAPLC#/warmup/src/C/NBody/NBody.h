#ifndef NBODY_H
#define NBODY_H
// intptr_t should be the native integer type on most sane systems.
typedef intptr_t intnative_t;

typedef struct{
    double position[3], velocity[3], mass;
} body;

#define SOLAR_MASS (4*M_PI*M_PI)
#define DAYS_PER_YEAR 365.24
#define BODIES_COUNT 5

int NBody(intnative_t n);

#endif
