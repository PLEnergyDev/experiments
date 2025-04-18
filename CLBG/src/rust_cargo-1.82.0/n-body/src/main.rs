// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// contributed by Cristi Cobzarenco

use std::ops::{Add, Sub, Mul};

#[link(name="rapl_interface")]
extern "C" {
    fn start_rapl() -> i32;
    fn stop_rapl();
}

const PI: f64 = 3.141592653589793;
const SOLAR_MASS: f64 = 4.0 * PI * PI;
const YEAR: f64 = 365.24;
const N_BODIES: usize = 5;
const N_PAIRS: usize = N_BODIES * (N_BODIES - 1) / 2;

static BODIES: [Planet; N_BODIES] = [
    Planet {
        pos: Vec3(0.0, 0.0, 0.0),
        vel: Vec3(0.0, 0.0, 0.0),
        mass: SOLAR_MASS,
    },
    Planet {
        pos: Vec3(
            4.84143144246472090e+00,
            -1.16032004402742839e+00,
            -1.03622044471123109e-01,
        ),
        vel: Vec3(
            1.66007664274403694e-03 * YEAR,
            7.69901118419740425e-03 * YEAR,
            -6.90460016972063023e-05 * YEAR,
        ),
        mass: 9.54791938424326609e-04 * SOLAR_MASS,
    },
    Planet {
        pos: Vec3(
            8.34336671824457987e+00,
            4.12479856412430479e+00,
            -4.03523417114321381e-01,
        ),
        vel: Vec3(
            -2.76742510726862411e-03 * YEAR,
            4.99852801234917238e-03 * YEAR,
            2.30417297573763929e-05 * YEAR,
        ),
        mass: 2.85885980666130812e-04 * SOLAR_MASS,
    },
    Planet {
        pos: Vec3(
            1.28943695621391310e+01,
            -1.51111514016986312e+01,
            -2.23307578892655734e-01,
        ),
        vel: Vec3(
            2.96460137564761618e-03 * YEAR,
            2.37847173959480950e-03 * YEAR,
            -2.96589568540237556e-05 * YEAR,
        ),
        mass: 4.36624404335156298e-05 * SOLAR_MASS,
    },
    Planet {
        pos: Vec3(
            1.53796971148509165e+01,
            -2.59193146099879641e+01,
            1.79258772950371181e-01,
        ),
        vel: Vec3(
            2.68067772490389322e-03 * YEAR,
            1.62824170038242295e-03 * YEAR,
            -9.51592254519715870e-05 * YEAR,
        ),
        mass: 5.15138902046611451e-05 * SOLAR_MASS,
    },
];

#[derive(Clone, Copy)]
struct Vec3(pub f64, pub f64, pub f64);

impl Vec3 {
    fn zero() -> Self {
        Vec3(0.0, 0.0, 0.0)
    }

    fn norm(&self) -> f64 {
        self.squared_norm().sqrt()
    }

    fn squared_norm(&self) -> f64 {
        self.0 * self.0 + self.1 * self.1 + self.2 * self.2
    }
}

impl Add for Vec3 {
    type Output = Self;
    fn add(self, rhs: Self) -> Self {
        Vec3(self.0 + rhs.0, self.1 + rhs.1, self.2 + rhs.2)
    }
}

impl Sub for Vec3 {
    type Output = Self;
    fn sub(self, rhs: Self) -> Self {
        Vec3(self.0 - rhs.0, self.1 - rhs.1, self.2 - rhs.2)
    }
}

impl Mul<f64> for Vec3 {
    type Output = Self;
    fn mul(self, rhs: f64) -> Self {
        Vec3(self.0 * rhs, self.1 * rhs, self.2 * rhs)
    }
}

#[derive(Clone, Copy)]
struct Planet {
    pos: Vec3,
    vel: Vec3,
    mass: f64,
}

fn pairwise_diffs(bodies: &[Planet; N_BODIES], diff: &mut [Vec3; N_PAIRS]) {
    let mut bodies = bodies.iter();
    let mut diff = diff.iter_mut();
    while let Some(bi) = bodies.next() {
        for bj in bodies.clone() {
            *diff.next().unwrap() = bi.pos - bj.pos;
        }
    }
}

fn magnitudes(diff: &[Vec3; N_PAIRS], dt: f64, mag: &mut [f64; N_PAIRS]) {
    for (mag, diff) in mag.iter_mut().zip(diff.iter()) {
        let d2 = diff.squared_norm();
        *mag = dt / (d2 * d2.sqrt());
    }
}

fn update_velocities(
    bodies: &mut [Planet; N_BODIES],
    dt: f64,
    diff: &mut [Vec3; N_PAIRS],
    mag: &mut [f64; N_PAIRS],
) {
    pairwise_diffs(bodies, diff);
    magnitudes(&diff, dt, mag);
    let mut bodies = &mut bodies[..];
    let mut mag = mag.iter();
    let mut diff = diff.iter();
    while let Some(bi) = shift_mut_ref(&mut bodies) {
        for bj in bodies.iter_mut() {
            let diff = *diff.next().unwrap();
            let mag = *mag.next().unwrap();
            bi.vel = bi.vel - diff * (bj.mass * mag);
            bj.vel = bj.vel + diff * (bi.mass * mag);
        }
    }
}

fn advance(
    bodies: &mut [Planet; N_BODIES],
    dt: f64,
    diff: &mut [Vec3; N_PAIRS],
    mag: &mut [f64; N_PAIRS],
) {
    update_velocities(bodies, dt, diff, mag);
    for body in bodies.iter_mut() {
        body.pos = body.pos + body.vel * dt;
    }
}

fn energy(bodies: &[Planet; N_BODIES]) -> f64 {
    let mut e = 0.0;
    let mut bodies = bodies.iter();
    while let Some(bi) = bodies.next() {
        e += bi.vel.squared_norm() * bi.mass / 2.0
            - bi.mass
                * bodies
                    .clone()
                    .map(|bj| bj.mass / (bi.pos - bj.pos).norm())
                    .fold(0.0, |a, b| a + b);
    }
    e
}

fn offset_momentum(bodies: &mut [Planet; N_BODIES]) {
    let p = bodies
        .iter()
        .fold(Vec3::zero(), |v, b| v + b.vel * b.mass);
    bodies[0].vel = p * (-1.0 / bodies[0].mass);
}

fn initialize(bodies: &mut [Planet; N_BODIES]) {
    *bodies = BODIES;
    offset_momentum(bodies);
}

fn run_benchmark(
    bodies: &mut [Planet; N_BODIES],
    diff: &mut [Vec3; N_PAIRS],
    mag: &mut [f64; N_PAIRS],
    n: usize,
) {
    println!("{:.9}", energy(&bodies));
    for _ in 0..n {
        advance(bodies, 0.01, diff, mag);
    }
    println!("{:.9}", energy(&bodies));
}

fn main() {
    let n: usize = std::env::args().nth(1)
        .and_then(|s| s.parse().ok())
        .unwrap();

    loop {
        let mut bodies = BODIES;
        let mut diff = [Vec3::zero(); N_PAIRS];
        let mut mag = [0.0f64; N_PAIRS];
        initialize(&mut bodies);
        if unsafe { start_rapl() } == 0 {
            break;
        }        
        run_benchmark(&mut bodies, &mut diff, &mut mag, n);
        unsafe { stop_rapl() };
    }
}

fn shift_mut_ref<'a, T>(r: &mut &'a mut [T]) -> Option<&'a mut T> {
    if r.len() == 0 {
        return None;
    }
    let tmp = std::mem::replace(r, &mut []);
    let (h, t) = tmp.split_at_mut(1);
    *r = t;
    Some(&mut h[0])
}
