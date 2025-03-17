from utils import read_csv_safely, calculate_energy
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
import argparse
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=str)
    parser.add_argument("-s", "--skip", type=int, default=0)
    return parser.parse_args()


def main():
    args = parse_args()

    rapl_rows = ["Time (ms)", "Pkg (J)", "Core (J)", "Uncore (J)", "Dram (J)"]

    df = read_csv_safely(args.input)
    if args.skip > 0:
        df = df.iloc[args.skip :]

    language = ""
    benchmark = ""

    p = Path(args.input)
    if len(p.parts) > 2:
        language = p.parts[-3]
        benchmark = p.parts[-2]

    power_unit = int(args.input.split("_")[-1].split(".")[0])
    pkg, core, uncore, dram, time = calculate_energy(df, power_unit)
    bench_df = pd.DataFrame(
        {
            "Time (ms)": time,
            "Pkg (J)": pkg,
            "Core (J)": core,
            "Uncore (J)": uncore,
            "Dram (J)": dram,
        }
    )

    fig, axs = plt.subplots(
        nrows=len(rapl_rows),
        ncols=2,
        figsize=(10, len(rapl_rows) * 5),
        sharey="row",
    )
    fig.subplots_adjust(hspace=0.4, wspace=0.4)

    for row_i, row in enumerate(rapl_rows):
        sns.violinplot(y=row, data=bench_df, ax=axs[row_i, 0])
        axs[row_i, 0].set_title(f"{language} - {benchmark} - Violin Plot")
        axs[row_i, 0].set_ylabel(row)

        sns.boxplot(y=row, data=bench_df, ax=axs[row_i, 1])
        axs[row_i, 1].set_title(f"{language} - {benchmark} - Box Plot")
        axs[row_i, 1].set_ylabel(row)

    plt.tight_layout()
    plt.savefig("violin.png")
    plt.close()


if __name__ == "__main__":
    main()
