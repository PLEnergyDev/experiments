// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// regex-dna program contributed by the Rust Project Developers
// contributed by BurntSushi
// contributed by TeXitoi
// converted from regex-dna program
// contributed by Matt Brubeck

extern crate regex;

use std::borrow::Cow;
use std::fs::File;
use std::io::{self, Read};
use std::sync::Arc;
use std::thread;
use rapl_lib::ffi::start_rapl;
use rapl_lib::ffi::stop_rapl;

macro_rules! regex {
    ($re:expr) => {
        ::regex::bytes::Regex::new($re).unwrap()
    };
}

fn read() -> io::Result<Vec<u8>> {
    let mut stdin = File::open("/dev/stdin")?;
    let size = stdin.metadata()?.len() as usize;
    let mut buf = Vec::with_capacity(size + 1);
    stdin.read_to_end(&mut buf)?;
    Ok(buf)
}

fn initialize() -> (Arc<Vec<u8>>, usize, usize) {
    let mut seq = read().unwrap();
    let ilen = seq.len();
    seq = regex!(">[^\n]*\n|\n")
        .replace_all(&seq, &b""[..])
        .into_owned();
    let clen = seq.len();
    let seq_arc = Arc::new(seq);
    (seq_arc, ilen, clen)
}

fn run_benchmark(seq_arc: &Arc<Vec<u8>>, ilen: usize, clen: usize) {
    let variants = vec![
        regex!("agggtaaa|tttaccct"),
        regex!("[cgt]gggtaaa|tttaccc[acg]"),
        regex!("a[act]ggtaaa|tttacc[agt]t"),
        regex!("ag[act]gtaaa|tttac[agt]ct"),
        regex!("agg[act]taaa|ttta[agt]cct"),
        regex!("aggg[acg]aaa|ttt[cgt]ccct"),
        regex!("agggt[cgt]aa|tt[acg]accct"),
        regex!("agggta[cgt]a|t[acg]taccct"),
        regex!("agggtaa[cgt]|[acg]ttaccct"),
    ];

    let mut counts = vec![];
    for variant in variants {
        let seq = seq_arc.clone();
        let restr = variant.to_string();
        let future = thread::spawn(move || variant.find_iter(&seq).count());
        counts.push((restr, future));
    }

    let substs = vec![
        (regex!("tHa[Nt]"), &b"<4>"[..]),
        (regex!("aND|caN|Ha[DS]|WaS"), &b"<3>"[..]),
        (regex!("a[NSt]|BY"), &b"<2>"[..]),
        (regex!("<[^>]*>"), &b"|"[..]),
        (regex!("\\|[^|][^|]*\\|"), &b"-"[..]),
    ];

    let mut seq = Cow::Borrowed(&seq_arc[..]);
    for (re, replacement) in substs {
        seq = Cow::Owned(re.replace_all(&seq, replacement).into_owned());
    }

    for (variant, count) in counts {
        println!("{} {}", variant, count.join().unwrap());
    }
    println!("\n{}\n{}\n{}", ilen, clen, seq.len());
}

fn cleanup() {}

fn main() {
    let iterations = std::env::args().nth(1)
        .and_then(|n| n.parse().ok())
        .unwrap_or(1);

    for _ in 0..iterations {
        let (seq_arc, ilen, clen) = initialize();
        start_rapl();
        run_benchmark(&seq_arc, ilen, clen);
        stop_rapl();
        cleanup();
    }
}
