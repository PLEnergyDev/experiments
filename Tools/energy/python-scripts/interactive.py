from pathlib import Path
from utils import read_csv_safely, calculate_energy
import pandas as pd
import argparse
import os


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "input",
        nargs="+",
    )
    parser.add_argument("-s", "--skip", type=int, default=0)
    parser.add_argument("-l", "--language", type=str, default="")
    return parser.parse_args()


def main():
    args = parse_args()
    for file in args.input:
        p = Path(file)
        language = p.parts[-3]
        benchmark = p.parts[-2]

        df = read_csv_safely(file)
        if args.skip > 0:
            df = df.iloc[args.skip :]


if __name__ == "__main__":
    main()
