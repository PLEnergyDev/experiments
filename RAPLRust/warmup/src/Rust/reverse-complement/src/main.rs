// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// contributed by the Rust Project Developers
// contributed by Cristi Cobzarenco
// contributed by TeXitoi
// contributed by Matt Brubeck

extern crate rayon;

use std::cmp::min;
use std::io::{Result, Write, stdin, stdout, Read};
use std::mem::replace;
use rapl_lib::ffi::start_rapl;
use rapl_lib::ffi::stop_rapl;

fn initialize() {
    // Initialization code (if needed)
}

fn run_benchmark(buffer: &[u8]) -> Result<()> {
    let table = build_table();
    let sequences = get_sequences(buffer, &table)?;
    for seq in sequences.iter().rev() {
        stdout().write_all(seq)?;
    }
    Ok(())
}

fn cleanup() {
    // Cleanup code (if needed)
}

fn main() -> Result<()> {
    let mut buffer = Vec::new();
    stdin().read_to_end(&mut buffer)?;

    let iterations: usize = std::env::args()
        .nth(1)
        .and_then(|n| n.parse().ok())
        .unwrap_or(1);
    for _ in 0..iterations {
        initialize();
        start_rapl();
        run_benchmark(&buffer)?;
        stop_rapl();
        cleanup();
    }
    Ok(())
}

fn build_table() -> [u8; 256] {
    let mut table = [0; 256];
    for (i, x) in table.iter_mut().enumerate() {
        *x = match i as u8 as char {
            'A' | 'a' => 'T',
            'C' | 'c' => 'G',
            'G' | 'g' => 'C',
            'T' | 't' => 'A',
            'U' | 'u' => 'A',
            'M' | 'm' => 'K',
            'R' | 'r' => 'Y',
            'W' | 'w' => 'W',
            'S' | 's' => 'S',
            'Y' | 'y' => 'R',
            'K' | 'k' => 'M',
            'V' | 'v' => 'B',
            'H' | 'h' => 'D',
            'D' | 'd' => 'H',
            'B' | 'b' => 'V',
            'N' | 'n' => 'N',
            i => i,
        } as u8;
    }
    table
}

fn get_sequences(buffer: &[u8], table: &[u8; 256]) -> Result<Vec<Vec<u8>>> {
    let mut buf = buffer.to_vec();
    let mut sequences = Vec::new();
    let mut start = 0;
    while let Some(end) = buf[start..].iter().position(|&x| x == b'>') {
        if start > 0 {
            reverse_complement(&mut buf[start..start + end], table);
            sequences.push(buf[start..start + end].to_vec());
        }
        start += end + 1;
    }
    reverse_complement(&mut buf[start..], table);
    sequences.push(buf[start..].to_vec());
    Ok(sequences)
}

fn reverse_complement(seq: &mut [u8], table: &[u8; 256]) {
    let len = seq.len() - 1;
    let seq = &mut seq[..len];
    let trailing_len = len % LINE_LEN;
    let (left, right) = seq.split_at_mut(len / 2);
    reverse_complement_left_right(left, right, trailing_len, table);
}

const LINE_LEN: usize = 61;
const SEQUENTIAL_SIZE: usize = 16 * 1024;

fn reverse_complement_left_right(mut left: &mut [u8],
                                 mut right: &mut [u8],
                                 trailing_len: usize,
                                 table: &[u8; 256]) {
    let len = left.len();
    if len <= SEQUENTIAL_SIZE {
        while left.len() > 0 || right.len() > 0 {
            let mut a = left.split_off_left(trailing_len);
            let mut b = right.split_off_right(trailing_len);
            right.split_off_right(1);

            if b.len() > a.len() {
                let mid = b.split_off_left(1);
                mid[0] = table[mid[0] as usize];
            }

            reverse_chunks(a, b, table);

            let n = LINE_LEN - 1 - trailing_len;
            a = left.split_off_left(n);
            b = right.split_off_right(n);
            left.split_off_left(1);

            if a.len() > b.len() {
                let mid = a.split_off_right(1);
                mid[0] = table[mid[0] as usize]
            }

            reverse_chunks(a, b, table);
        }
    } else {
        let line_count = len / LINE_LEN;
        let mid = line_count / 2 * LINE_LEN;

        let left1 = left.split_off_left(mid);
        let right1 = right.split_off_right(mid);
        rayon::join(|| reverse_complement_left_right(left, right, trailing_len, table),
                    || reverse_complement_left_right(left1, right1, trailing_len, table));
    }
}

fn reverse_chunks(left: &mut [u8], right: &mut [u8], table: &[u8; 256]) {
    for (x, y) in left.iter_mut().zip(right.iter_mut().rev()) {
        *y = table[replace(x, table[*y as usize]) as usize];
    }
}

trait SplitOff {
    fn split_off_left(&mut self, n: usize) -> Self;
    fn split_off_right(&mut self, n: usize) -> Self;
}
impl<'a, T> SplitOff for &'a mut [T] {
    fn split_off_left(&mut self, n: usize) -> Self {
        let n = min(self.len(), n);
        let data = replace(self, &mut []);
        let (left, data) = data.split_at_mut(n);
        *self = data;
        left
    }
    fn split_off_right(&mut self, n: usize) -> Self {
        let len = self.len();
        let n = min(len, n);
        let data = replace(self, &mut []);
        let (data, right) = data.split_at_mut(len - n);
        *self = data;
        right
    }
}
