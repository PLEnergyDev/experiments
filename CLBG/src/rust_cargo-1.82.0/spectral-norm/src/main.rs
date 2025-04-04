// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// contributed by the Rust Project Developers
// contributed by Matt Brubeck
// contributed by TeXitoi
// modified by Tung Duong
// contributed by Cristi Cobzarenco

extern crate rayon;
use rayon::prelude::*;

#[link(name="rapl_interface")]
extern "C" {
    fn start_rapl() -> i32;
    fn stop_rapl();
}

fn run_benchmark(n: usize) {
    let answer = spectralnorm(n);
    println!("{:.9}", answer);
}

fn main() {
    let n = std::env::args().nth(1)
        .and_then(|n| n.parse().ok())
        .unwrap();

    loop {
        if unsafe { start_rapl() } == 0 {
            break;
        }
        run_benchmark(n);
        unsafe { stop_rapl() };
    }
}

fn spectralnorm(n: usize) -> f64 {
    assert!(n % 2 == 0, "only even lengths are accepted");
    let mut u = vec![[1.0, 1.0]; n / 2];
    let mut v = vec![[0.0, 0.0]; n / 2];
    let mut tmp = vec![[0.0, 0.0]; n / 2];

    for _ in 0..10 {
        mult_at_av(&u, &mut v, &mut tmp);
        mult_at_av(&v, &mut u, &mut tmp);
    }

    (dot(&u, &v) / dot(&v, &v)).sqrt()
}

fn mult_at_av(v: &[[f64; 2]], out: &mut [[f64; 2]], tmp: &mut [[f64; 2]]) {
    mult(v, tmp, a);
    mult(tmp, out, |i, j| a(j, i));
}

fn mult<F>(v: &[[f64; 2]], out: &mut [[f64; 2]], a: F)
where
    F: Fn([usize; 2], [usize; 2]) -> [f64; 2] + Sync,
{
    out.par_iter_mut().enumerate().for_each(|(i, slot)| {
        let i = 2 * i;
        let (i0, i1) = ([i; 2], [i + 1; 2]);

        let (mut sum0, mut sum1) = ([0.0; 2], [0.0; 2]);
        for (j, x) in v.iter().enumerate() {
            let j = [2 * j, 2 * j + 1];
            div_and_add(x, &a(i0, j), &a(i1, j), &mut sum0, &mut sum1);
        }

        slot[0] = sum0[0] + sum0[1];
        slot[1] = sum1[0] + sum1[1];
    });
}

fn a(i: [usize; 2], j: [usize; 2]) -> [f64; 2] {
    [
        ((i[0] + j[0]) * (i[0] + j[0] + 1) / 2 + i[0] + 1) as f64,
        ((i[1] + j[1]) * (i[1] + j[1] + 1) / 2 + i[1] + 1) as f64,
    ]
}

fn dot(v: &[[f64; 2]], u: &[[f64; 2]]) -> f64 {
    let r = u
        .iter()
        .zip(v)
        .map(|(x, y)| [x[0] * y[0], x[1] * y[1]])
        .fold([0.0f64; 2], |s, x| [s[0] + x[0], s[1] + x[1]]);

    r[0] + r[1]
}

#[inline(never)]
fn div_and_add(
    x: &[f64; 2],
    a0: &[f64; 2],
    a1: &[f64; 2],
    s0: &mut [f64; 2],
    s1: &mut [f64; 2],
) {
    s0[0] += x[0] / a0[0];
    s0[1] += x[1] / a0[1];
    s1[0] += x[0] / a1[0];
    s1[1] += x[1] / a1[1];
}
