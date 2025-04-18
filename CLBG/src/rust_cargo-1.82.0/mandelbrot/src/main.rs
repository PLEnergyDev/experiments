// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// contributed by Matt Watson
// contributed by TeXitoi
// contributed by Volodymyr M. Lisivka
// contributed by Michael Cicotti

extern crate generic_array;
extern crate num_traits;
extern crate numeric_array;
extern crate rayon;

use generic_array::typenum::consts::U8;
use numeric_array::NumericArray as Arr;
use rayon::prelude::*;
use std::io::Write;

#[link(name="rapl_interface")]
extern "C" {
    fn start_rapl() -> i32;
    fn stop_rapl();
}

type Vecf64 = Arr<f64, U8>;
type Constf64 = numeric_array::NumericConstant<f64>;

const MAX_ITER: usize = 50;
const VLEN: usize = 8;

#[inline(always)]
pub fn mbrot8(out: &mut u8, cr: Vecf64, ci: Constf64) {
    let mut zr = Arr::splat(0f64);
    let mut zi = Arr::splat(0f64);
    let mut tr = Arr::splat(0f64);
    let mut ti = Arr::splat(0f64);
    let mut absz = Arr::splat(0f64);

    for _ in 0..MAX_ITER / 5 {
        for _ in 0..5 {
            zi = (zr + zr) * zi + ci;
            zr = tr - ti + cr;
            tr = zr * zr;
            ti = zi * zi;
        }
        absz = tr + ti;
        if absz.iter().all(|&t| t > 4.) {
            return;
        }
    }
    *out = absz.iter().enumerate().fold(0, |accu, (i, &t)| {
        accu | if t <= 4. { 0x80 >> i } else { 0 }
    });
}

fn initialize(size: usize) -> (f64, Vec<Vecf64>, Vec<u8>) {
    let inv = 2. / size as f64;
    let mut xloc = vec![Arr::splat(0f64); size / VLEN];
    for i in 0..size {
        xloc[i / VLEN][i % VLEN] = i as f64 * inv - 1.5;
    }
    let rows = vec![0; size * size / VLEN];
    (inv, xloc, rows)
}

fn run_benchmark(size: usize, inv: f64, xloc: &Vec<Vecf64>, rows: &mut Vec<u8>) {
    rows.par_chunks_mut(size / VLEN)
        .enumerate()
        .for_each(|(y, out)| {
            let ci = numeric_array::NumericConstant(y as f64 * inv - 1.);
            out.iter_mut()
                .enumerate()
                .for_each(|(i, inner_out)| mbrot8(inner_out, xloc[i], ci));
        });
}

fn main() {
    let size_input: usize = std::env::args().nth(1)
        .and_then(|n| n.parse().ok())
        .unwrap();
    let size = size_input / VLEN * VLEN;
    println!("P4\n{} {}", size, size);

    loop {
        let (inv, xloc, mut rows) = initialize(size);
        if unsafe { start_rapl() } == 0 {
            break;
        }
        run_benchmark(size, inv, &xloc, &mut rows);
        let stdout_unlocked = std::io::stdout();
        let mut stdout = stdout_unlocked.lock();
        let _ = stdout.write_all(&rows);
        unsafe { stop_rapl() };
    }
}
