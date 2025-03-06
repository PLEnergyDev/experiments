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

    avg_time = 0
    avg_pkg = 0
    avg_core = 0
    avg_uncore = 0
    avg_dram = 0

    for file in args.input:
        df = read_csv_safely(file)
        if args.skip > 0:
            df = df.iloc[args.skip :]

        power_unit = int(file.split("_")[-1].split(".")[0])
        pkg, core, uncore, dram, time = calculate_energy(df, power_unit)
        avg_time += time.mean()
        avg_pkg += pkg.mean()
        avg_core += core.mean()
        avg_uncore += uncore.mean()
        avg_dram += dram.mean()

    avg_time /= len(args.input)
    avg_pkg /= len(args.input)
    avg_core /= len(args.input)
    avg_uncore /= len(args.input)
    avg_dram /= len(args.input)

    averaged_data = {
        "Language": args.language,
        "Average Time (ms)": avg_time,
        "Average Pkg (J)": avg_pkg,
        "Average Core (J)": avg_core,
        "Average Uncore (J)": avg_uncore,
        "Average Dram (J)": avg_dram,
    }

    if os.path.exists("averaged.csv"):
        averaged_df = pd.read_csv("averaged.csv")
        averaged_df = pd.concat(
            [averaged_df, pd.DataFrame([averaged_data])],
            ignore_index=True,
        )
    else:
        averaged_df = pd.DataFrame([averaged_data])
    averaged_df.to_csv("averaged.csv", index=False)


if __name__ == "__main__":
    main()
