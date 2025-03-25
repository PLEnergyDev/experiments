from utils import read_csv_safely, calculate_energy
import pandas as pd
import argparse
from pathlib import Path
import os


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", nargs="+")
    return parser.parse_args()


def main():
    args = parse_args()

    df_list = []
    for file in args.input:
        p = Path(file)
        if len(p.parts) > 2:
            language = p.parts[-3]
            benchmark = p.parts[-2]
        else:
            language = ""
            benchmark = ""

        df = read_csv_safely(file)
        power_unit = int(file.split("_")[-1].split(".")[0])
        pkg, core, uncore, dram, time = calculate_energy(df, power_unit)

        # Round all float values to 2 decimal places
        time = time.round(2)
        pkg = pkg.round(2)
        core = core.round(2)
        uncore = uncore.round(2)
        dram = dram.round(2)

        tmp_df = pd.DataFrame(
            {
                "Language": language,
                "Benchmark": benchmark,
                "Time (ms)": time,
                "Pkg (J)": pkg,
                "Core (J)": core,
                "Uncore (J)": uncore,
                "Dram (J)": dram,
            }
        )
        df_list.append(tmp_df)

    # Concatenate all new DataFrames into one
    new_data = pd.concat(df_list, ignore_index=True)

    if os.path.exists("rapl.csv"):
        # Read existing CSV and append the new data
        compiled_df = pd.read_csv("rapl.csv")
        compiled_df = pd.concat([compiled_df, new_data], ignore_index=True)
    else:
        compiled_df = new_data

    compiled_df.to_csv("rapl.csv", index=False)


if __name__ == "__main__":
    main()
