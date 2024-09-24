import os
import pandas as pd

languages = [
    "C",
    "C++",
    "C#",
    "Rust",
    "Java",
    # "JavaScript",
    # "Python"
]  # 7 languages
algorithms = [  # 9 benchmarks
    "binary-trees",
    # "chameneos-redux",
    "fannkuch-redux",
    "fasta",
    "k-nucleotide",
    "mandelbrot",
    "n-body",
    # "pidigits",
    "regex-redux",
    "reverse-complement",
    "spectral-norm",
]
rapl_columns = [
    "TimeStart",
    "TimeEnd",
    "PP0Start",
    "PP0End",
    "PP1Start",
    "PP1End",
    "PkgStart",
    "PkgEnd",
    "DramStart",
    "DramEnd",
]
rapl_csv = "rapl.csv"


def main():
    for language in languages:
        global_rapl_data = []
        global_rapl_results = os.path.join(language, rapl_csv)
        for algorithm in algorithms:
            rapl_results = os.path.join(language, algorithm, rapl_csv)

            if not os.path.exists(rapl_results):
                continue
            rapl_df = pd.read_csv(rapl_results, header=0)
            pkg = (rapl_df["PkgEnd"] - rapl_df["PkgStart"]) * 6.103515625e-05
            core = (rapl_df["PP0End"] - rapl_df["PP0Start"]) * 6.103515625e-05
            uncore = (rapl_df["PP1End"] - rapl_df["PP1Start"]) * 6.103515625e-05
            dram = (rapl_df["DramEnd"] - rapl_df["DramStart"]) * 6.103515625e-05
            time = rapl_df["TimeEnd"] - rapl_df["TimeStart"]
            for i in range(len(rapl_df)):
                global_rapl_data.append(
                    [algorithm, pkg[i], core[i], uncore[i], dram[i], time[i]]
                )

        global_rapl_results_df = pd.DataFrame(global_rapl_data)
        global_rapl_results_df.to_csv(global_rapl_results, header=False, index=False)


if __name__ == "__main__":
    main()
