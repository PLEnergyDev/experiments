import os
import re
import pandas as pd
import numpy as np
import scipy.cluster.hierarchy as sch
import matplotlib.pyplot as plt
import seaborn as sns
from tqdm import tqdm
import matplotlib.pyplot as plt

# BENCHMARK_SETS = ["no-warmup", "warmup"]
# BENCHMARK_SETS = ["no-warmup"]
BENCHMARK_SETS = ["warmup"]
# BENCHMARK_LANGUAGES = ["C", "C++", "C#", "Java", "Rust"]
BENCHMARK_LANGUAGES = ["C", "C#"]
BENCHMARKS = [
    "binary-trees",
    "division-loop",
    "fannkuch-redux",
    "fasta",
    "k-nucleotide",
    "mandelbrot",
    "matrix-multiplication",
    "n-body",
    "polynomial-evaluation",
    "regex-redux",
    "reverse-complement",
    "spectral-norm",
]
RAPL_COLUMNS = [
    "Algorithm",
    "Package Energy (J)",
    "Core Energy (J)",
    "Uncore Energy (J)",
    "DRAM Energy (J)",
    "Elapsed Time (ms)",
]
MEM_COLUMNS = ["Algorithm", "Total Memory (MB)", "Peak Memory (MB)"]
AVERAGED_COLUMNS = [
    "Language",
    "Energy (J)",
    "Time (ms)",
    "Ratio (J/ms)",
]
NORMALIZED_COLUMNS = ["Energy (J)", "Time (ms)"]


def compile():
    for sett in BENCHMARK_SETS:
        for lang in BENCHMARK_LANGUAGES:
            lang_dir = os.path.join(sett, "results", lang)

            lang_data = []
            for bench in BENCHMARKS:
                bench_results = os.path.join(lang_dir, bench, "rapl.csv")

                if not os.path.exists(bench_results):
                    print(
                        f"[ERROR] Missing benchmark results '{bench_results}'. Exiting."
                    )
                    return

                # print(f"[INFO] {bench_results}")
                bench_df = pd.read_csv(bench_results, header=0, comment="T")
                pkg = (bench_df.iloc[:, 7] - bench_df.iloc[:, 6]) * 6.103515625e-05
                core = (bench_df.iloc[:, 3] - bench_df.iloc[:, 2]) * 6.103515625e-05
                uncore = (bench_df.iloc[:, 5] - bench_df.iloc[:, 4]) * 6.103515625e-05
                dram = (bench_df.iloc[:, 9] - bench_df.iloc[:, 8]) * 6.103515625e-05
                time = bench_df.iloc[:, 1] - bench_df.iloc[:, 0]

                for i in range(len(bench_df)):
                    lang_data.append(
                        [bench, pkg[i], core[i], uncore[i], dram[i], time[i]]
                    )

            lang_results = os.path.join(lang_dir, "rapl.csv")
            lang_df = pd.DataFrame(lang_data)
            lang_df.to_csv(lang_results, header=False, index=False)


# def separate_results():
#     for sett in BENCHMARK_SETS:
#         for lang in BENCHMARK_LANGUAGES:
#             lang_results = os.path.join(sett, lang, "rapl.csv")
#             if not os.path.exists(lang_results):
#                 print(f"[ERROR] Missing compiled language results '{lang_results}'. Exiting.")
#                 return

#             lang_df = pd.read_csv(lang_results, header=None)
#             lang_df.columns = RAPL_COLUMNS

#             for bench in BENCHMARKS:
#                 if bench not in list(lang_df["Algorithm"]):
#                     print(f"[ERROR] Missing benchmark results in compiled language results '{lang_results}'. Exiting.")
#                     return

#                 bench_dir =
#                 bench_df = lang_df[lang_df["Algorithm"] == bench]


def average_results(skip=15):
    for sett in BENCHMARK_SETS:
        for lang in BENCHMARK_LANGUAGES:
            lang_results = os.path.join(sett, "results", lang, "rapl.csv")
            if not os.path.exists(lang_results):
                print(
                    f"[ERROR] Missing compiled language results '{lang_results}'. Exiting."
                )
                return

            lang_df = pd.read_csv(lang_results, header=None)
            lang_df.columns = RAPL_COLUMNS
            for bench in BENCHMARKS:
                if bench not in list(lang_df["Algorithm"]):
                    print(
                        f"[ERROR] Missing benchmark results in compiled language results '{lang_results}'. Exiting."
                    )
                    return

                averaged_dir = os.path.join(sett, "results", "averaged")
                averaged_results = os.path.join(
                    sett, "results", "averaged", f"{bench}.csv"
                )
                if not os.path.exists(averaged_dir):
                    os.mkdir(averaged_dir)

                bench_df = lang_df[lang_df["Algorithm"] == bench][skip:]
                energy = bench_df["Package Energy (J)"] + bench_df["DRAM Energy (J)"]
                time = bench_df["Elapsed Time (ms)"]
                # memory = mem_df["Total Memory (MB)"]
                # peak = mem_df["Peak Memory (MB)"]
                avg_energy = energy.mean()
                avg_time = time.mean()
                # avg_memory = memory.mean()
                # avg_peak = peak.mean()
                if avg_time > 0:
                    ratio = avg_energy / avg_time
                else:
                    ratio = 0

                averaged_data = {
                    AVERAGED_COLUMNS[0]: lang,
                    AVERAGED_COLUMNS[1]: avg_energy,
                    AVERAGED_COLUMNS[2]: avg_time,
                    AVERAGED_COLUMNS[3]: ratio,
                    # AVERAGED_COLUMNS[4]: avg_memory,
                    # AVERAGED_COLUMNS[5]: avg_peak,
                }
                if os.path.exists(averaged_results):
                    results_df = pd.read_csv(averaged_results)
                    results_df = pd.concat(
                        [results_df, pd.DataFrame([averaged_data])], ignore_index=True
                    )
                else:
                    results_df = pd.DataFrame([averaged_data])

                results_df = results_df.round(2)
                results_df.to_csv(averaged_results, index=False)


def normalize_results(skip=15):
    for sett in BENCHMARK_SETS:
        energy = 0
        time = 0
        normalized_dict = {}
        normalized_result = os.path.join(sett, "results", "normalized.csv")
        for lang in BENCHMARK_LANGUAGES:
            lang_results = os.path.join(sett, "results", lang, "rapl.csv")
            if not os.path.exists(lang_results):
                print(
                    f"[ERROR] Missing compiled language results '{lang_results}'. Exiting."
                )
                return

            lang_df = pd.read_csv(lang_results, header=None)
            lang_df.columns = RAPL_COLUMNS
            for bench in BENCHMARKS:
                if bench not in list(lang_df["Algorithm"]):
                    print(
                        f"[ERROR] Missing benchmark results in compiled language results '{lang_results}'. Exiting."
                    )
                    return

                bench_df = lang_df[lang_df["Algorithm"] == bench][skip:]
                energy_df = bench_df["Package Energy (J)"] + bench_df["DRAM Energy (J)"]
                time_df = bench_df["Elapsed Time (ms)"]

                energy += energy_df.mean()
                time += time_df.mean()

            energy = energy / len(BENCHMARKS)
            time = time / len(BENCHMARKS)

            normalized_dict[lang] = (energy, time)
        normalized_df = (
            pd.DataFrame.from_dict(
                normalized_dict, orient="index", columns=NORMALIZED_COLUMNS
            )
            .reset_index()
            .rename(columns={"index": "Language"})
        )
        min_energy = normalized_df["Energy (J)"].min()
        min_time = normalized_df["Time (ms)"].min()

        normalized_df["Normalized Energy (J)"] = (
            normalized_df["Energy (J)"] / min_energy
        )
        normalized_df["Normalized Time (ms)"] = normalized_df["Time (ms)"] / min_time

        energy_df = (
            normalized_df[["Language", "Energy (J)", "Normalized Energy (J)"]]
            .sort_values(by="Normalized Energy (J)")
            .round(2)
        )
        time_df = (
            normalized_df[["Language", "Time (ms)", "Normalized Time (ms)"]]
            .sort_values(by="Normalized Time (ms)")
            .round(2)
        )
        normalized_df = pd.DataFrame(
            {
                "Language (Energy)": energy_df["Language"].values,
                "Energy (J)": energy_df["Energy (J)"].values,
                "Normalized Energy": energy_df["Normalized Energy (J)"].values,
                "Language (Time)": time_df["Language"].values,
                "Time (ms)": time_df["Time (ms)"].values,
                "Normalized Time": time_df["Normalized Time (ms)"].values,
            }
        )

        normalized_df.to_csv(normalized_result, index=False)


def _dendrogram_energy(data, labels, plots_dir):
    dendogram_result = os.path.join(plots_dir, "dendogram_energy.png")
    linked = sch.linkage(data[:, None], method="ward")

    plt.figure(figsize=(10, 7))
    sch.dendrogram(
        linked, labels=labels, color_threshold=0, above_threshold_color="blue"
    )
    plt.title("Energy Consumption - CPU + DRAM")
    plt.xlabel("Programming Languages")
    plt.ylabel("Joules")
    plt.savefig(dendogram_result)


def _dendrogram_time(data, labels, plots_dir):
    dendogram_result = os.path.join(plots_dir, "dendogram_time.png")
    linked = sch.linkage(data[:, None], method="ward")

    plt.figure(figsize=(10, 7))
    sch.dendrogram(
        linked, labels=labels, color_threshold=0, above_threshold_color="blue"
    )
    plt.title("Elapsed Time")
    plt.xlabel("Programming Languages")
    plt.ylabel("Milliseconds")
    plt.savefig(dendogram_result)


def dendrograms():
    dendrogram_functions = [
        _dendrogram_energy,
        _dendrogram_time,
    ]

    for sett in BENCHMARK_SETS:
        energy = 0
        time = 0
        normalized_dict = {}
        for lang in BENCHMARK_LANGUAGES:
            lang_results = os.path.join(sett, "results", lang, "rapl.csv")
            if not os.path.exists(lang_results):
                print(
                    f"[ERROR] Missing compiled language results '{lang_results}'. Exiting."
                )
                return

            lang_df = pd.read_csv(lang_results, header=None)
            lang_df.columns = RAPL_COLUMNS
            for bench in BENCHMARKS:
                if bench not in list(lang_df["Algorithm"]):
                    print(
                        f"[ERROR] Missing benchmark results in compiled language results '{lang_results}'. Exiting."
                    )
                    return

                bench_df = lang_df[lang_df["Algorithm"] == bench]
                energy_df = bench_df["Package Energy (J)"] + bench_df["DRAM Energy (J)"]
                time_df = bench_df["Elapsed Time (ms)"]

                energy += energy_df.mean()
                time += time_df.mean()

            energy = energy / len(BENCHMARKS)
            time = time / len(BENCHMARKS)

            normalized_dict[lang] = (energy, time)

        plots_dir = os.path.join(sett, "results", "plots", "dendrograms")
        if not os.path.exists(plots_dir):
            os.makedirs(plots_dir)

        for i in range(len(dendrogram_functions)):
            function = dendrogram_functions[i]
            data = np.array([])
            labels = []
            for language, normalized_results in normalized_dict.items():
                data = np.append(data, normalized_results[i])
                labels.append(language)
            function(data, labels, plots_dir)


def violins():
    for sett in BENCHMARK_SETS:
        plots_dir = os.path.join(sett, "results", "plots", "violins")
        if not os.path.exists(plots_dir):
            os.makedirs(plots_dir)

        for lang in BENCHMARK_LANGUAGES:
            for bench in BENCHMARKS:
                bench_results = os.path.join(
                    sett, "results", lang, bench, "results.csv"
                )
                if not os.path.exists(bench_results):
                    print(
                        f"[ERROR] Missing benchmark results in '{bench_results}'. Exiting."
                    )
                    continue
                    # return

                rows = RAPL_COLUMNS[1:]
                experiments = {
                    f"{sett}": {
                        f"{lang} {bench}": bench_results,
                    }
                }
                fig, axs = plt.subplots(
                    nrows=len(rows),
                    ncols=len(experiments) * 2,
                    figsize=(len(experiments) * 15, len(rows) * 5),
                    sharey="row",
                )
                fig.subplots_adjust(hspace=0.4, wspace=0.4)

                for exp_i, (experiment_name, conditions) in enumerate(
                    experiments.items()
                ):
                    for condition_name, file_path in conditions.items():
                        df = pd.read_csv(file_path)

                        for row_i, row in enumerate(rows):
                            # Prepare data for plotting
                            combined_data = df.assign(Condition=condition_name)

                            # Determine the subplot index
                            violin_ax_index = row_i, exp_i
                            box_ax_index = row_i, exp_i + len(experiments)

                            # Plot violin plot
                            sns.violinplot(
                                x="Condition",
                                y=row,
                                data=combined_data,
                                ax=axs[violin_ax_index],
                            )

                            # Plot box plot
                            sns.boxplot(
                                x="Condition",
                                y=row,
                                data=combined_data,
                                ax=axs[box_ax_index],
                            )

                            # Set titles
                            axs[violin_ax_index].set_title(row)
                            axs[box_ax_index].set_title(row)
                            axs[violin_ax_index].set_xlabel(experiment_name)
                            axs[box_ax_index].set_xlabel(experiment_name)

                lang_dir = os.path.join(plots_dir, lang)
                if not os.path.exists(lang_dir):
                    os.makedirs(lang_dir)

                violin_result = os.path.join(lang_dir, f"{bench}.png")
                plt.tight_layout()
                plt.savefig(violin_result)
                plt.close()


def caches(step=10):
    for sett in BENCHMARK_SETS:
        plots_dir = os.path.join(sett, "results", "plots", "caches")
        if not os.path.exists(plots_dir):
            os.makedirs(plots_dir)

        for lang in BENCHMARK_LANGUAGES:
            for bench in BENCHMARKS:
                bench_results = os.path.join(sett, "results", lang, bench, "cache.txt")
                if not os.path.exists(bench_results):
                    print(
                        f"[ERROR] Missing benchmark results in '{bench_results}'. Exiting."
                    )
                    return

                timestamps = []
                metrics = {
                    # "Cache Misses": [],
                    # "Cache References": [],
                    "LLC Load Misses": [],
                    # "LLC Loads": [],
                }

                parsed_data = []

                with open(bench_results, "r") as file:
                    for line in file:
                        parts = re.split(r"\s+", line.strip())
                        if len(parts) < 2:
                            continue
                        if "cache-misses" in line:
                            parsed_data.append(
                                {
                                    "timestamp": float(parts[0]),
                                    "Cache Misses": int(
                                        parts[1].replace(",", "").replace(".", "")
                                    ),
                                }
                            )
                        elif "cache-references" in line:
                            if (
                                parsed_data
                                and "Cache References" not in parsed_data[-1]
                            ):
                                parsed_data[-1]["Cache References"] = int(
                                    parts[1].replace(",", "").replace(".", "")
                                )
                        elif "LLC-loads-misses" in line:
                            if parsed_data and "LLC Load Misses" not in parsed_data[-1]:
                                parsed_data[-1]["LLC Load Misses"] = int(
                                    parts[1].replace(",", "").replace(".", "")
                                )
                        elif "LLC-loads" in line:
                            if parsed_data and "LLC Loads" not in parsed_data[-1]:
                                parsed_data[-1]["LLC Loads"] = int(
                                    parts[1].replace(",", "").replace(".", "")
                                )

                # Extract aligned data
                for entry in parsed_data:
                    timestamps.append(entry["timestamp"])
                    for key in metrics.keys():
                        metrics[key].append(
                            entry.get(key, 0)
                        )  # Default missing data to 0

                timestamps = timestamps[::step]
                metrics = {key: values[::step] for key, values in metrics.items()}

                # Skip if there is no data
                if not timestamps or all(
                    len(values) == 0 for values in metrics.values()
                ):
                    print(f"No valid data for {lang} - {bench}")
                    return

                # Plot the metrics
                plt.figure(figsize=(12, 6))
                for key, values in metrics.items():
                    if values:  # Only plot if data exists
                        plt.plot(timestamps, values, label=key, marker="o")

                lang_dir = os.path.join(plots_dir, lang)
                if not os.path.exists(lang_dir):
                    os.makedirs(lang_dir)

                # Save the figure
                figure_path = os.path.join(lang_dir, f"{bench}.png")
                plt.xlabel("Time (seconds)")
                plt.ylabel("Count")
                plt.title(f"Cache Metrics Over Time: {lang} - {bench}")
                plt.legend()
                plt.grid(True)
                plt.tight_layout()
                plt.savefig(figure_path)
                plt.close()


def main():
    print(f"[INFO] Compiling benchmark results...")
    compile()
    print(f"[INFO] Averaging results...")
    average_results()
    print(f"[INFO] Normalizing results...")
    normalize_results()
    print(f"[INFO] Plotting dendrograms...")
    # dendrograms()
    print(f"[INFO] Plotting violins...")
    # violins()
    print(f"[INFO] Plotting caches...")
    caches(25)
    print(f"[INFO] Done!")


if __name__ == "__main__":
    main()
