import os
import pandas as pd
import numpy as np
import scipy.cluster.hierarchy as sch
import matplotlib.pyplot as plt

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
    # "reverse-complement",
    "spectral-norm",
]
rapl_columns = [
    "Algorithm",
    "Package Energy (J)",
    "Core Energy (J)",
    "Uncore Energy (J)",
    "DRAM Energy (J)",
    "Elapsed Time (ms)",
]
mem_columns = ["Algorithm", "Total Memory (MB)", "Peak Memory (MB)"]
averaged_columns = [
    "Language",
    "Energy (J)",
    "Time (ms)",
    "Ratio (J/ms)",
    "Memory (MB)",
    "Peak (MB)",
]
normalized_columns = [
    "Energy (J)",
    "Time (ms)",
    "Memory (MB)",
    "Peak (MB)",
]
rapl_csv = "rapl.csv"
mem_csv = "mem.csv"
results_csv = "results.csv"
averaged_dir = "Averaged"
normalized_csv = "normalized.csv"
plots_dir = "Plots"
dendogram_energy_png = "dendogram_energy.png"
dendogram_time_png = "dendogram_time.png"
dendogram_memory_png = "dendogram_memory.png"
dendogram_peak_png = "dendogram_peak.png"


def separate_results(rapl_df, mem_df, language, algorithm):
    algorithm_dir = os.path.join(language, algorithm)
    results = os.path.join(algorithm_dir, results_csv)

    if not os.path.exists(algorithm_dir):
        os.mkdir(algorithm_dir)

    rapl_df = rapl_df.round(2)
    mem_df = mem_df.round(2)

    results_df = pd.merge(rapl_df, mem_df, on="Algorithm", how="inner")
    results_df.to_csv(results, index=False)


def average_results(rapl_df, mem_df, language, algorithm):
    results = os.path.join(averaged_dir, f"{algorithm}.csv")

    if not os.path.exists(averaged_dir):
        os.mkdir(averaged_dir)

    energy = rapl_df["Package Energy (J)"] + rapl_df["DRAM Energy (J)"]
    time = rapl_df["Elapsed Time (ms)"]
    memory = mem_df["Total Memory (MB)"]
    peak = mem_df["Peak Memory (MB)"]
    avg_energy = energy.mean()
    avg_time = time.mean()
    avg_memory = memory.mean()
    avg_peak = peak.mean()

    if avg_time > 0:
        ratio = avg_energy / avg_time
    else:
        ratio = 0

    new_data = {
        averaged_columns[0]: language,
        averaged_columns[1]: avg_energy,
        averaged_columns[2]: avg_time,
        averaged_columns[3]: ratio,
        averaged_columns[4]: avg_memory,
        averaged_columns[5]: avg_peak,
    }

    if os.path.exists(results):
        results_df = pd.read_csv(results)
        results_df = pd.concat(
            [results_df, pd.DataFrame([new_data])], ignore_index=True
        )
    else:
        results_df = pd.DataFrame([new_data])

    results_df = results_df.round(2)

    results_df.to_csv(results, index=False)

    return avg_energy, avg_time, avg_memory, avg_peak


# C, (energy, time, memory, peak)
# C++, (energy, time, memory, peak)
# C#, (energy, time, memory, peak)
# Java, (energy, time, memory, peak)
# Rust, (energy, time, memory, peak)


def normalize_results(results):
    # Convert results dictionary into a DataFrame
    results_df = (
        pd.DataFrame.from_dict(
            results,
            orient="index",
            columns=["Energy (J)", "Time (ms)", "Memory (MB)", "Peak (MB)"],
        )
        .reset_index()
        .rename(columns={"index": "Language"})
    )

    min_energy = results_df["Energy (J)"].min()
    min_time = results_df["Time (ms)"].min()
    min_memory = results_df["Memory (MB)"].min()
    min_peak = results_df["Peak (MB)"].min()

    results_df["Normalized Energy (J)"] = results_df["Energy (J)"] / min_energy
    results_df["Normalized Time (ms)"] = results_df["Time (ms)"] / min_time
    results_df["Normalized Memory (MB)"] = results_df["Memory (MB)"] / min_memory
    results_df["Normalized Peak (MB)"] = results_df["Peak (MB)"] / min_peak

    energy_df = (
        results_df[["Language", "Energy (J)", "Normalized Energy (J)"]]
        .sort_values(by="Normalized Energy (J)")
        .round(2)
    )
    time_df = (
        results_df[["Language", "Time (ms)", "Normalized Time (ms)"]]
        .sort_values(by="Normalized Time (ms)")
        .round(2)
    )
    memory_df = (
        results_df[["Language", "Memory (MB)", "Normalized Memory (MB)"]]
        .sort_values(by="Normalized Memory (MB)")
        .round(2)
    )
    peak_df = (
        results_df[["Language", "Peak (MB)", "Normalized Peak (MB)"]]
        .sort_values(by="Normalized Peak (MB)")
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
            "Language (Memory)": memory_df["Language"].values,
            "Memory (MB)": memory_df["Memory (MB)"].values,
            "Normalized Memory": memory_df["Normalized Memory (MB)"].values,
            "Language (Peak)": peak_df["Language"].values,
            "Peak (MB)": peak_df["Peak (MB)"].values,
            "Normalized Peak": peak_df["Normalized Peak (MB)"].values,
        }
    )

    normalized_df.to_csv(normalized_csv, index=False)


def dendogram_energy(data, labels):
    dendogram = os.path.join(plots_dir, "dendogram_energy.png")
    linked = sch.linkage(data[:, None], method="ward")

    plt.figure(figsize=(10, 7))
    sch.dendrogram(
        linked, labels=labels, color_threshold=0, above_threshold_color="blue"
    )
    plt.title("Energy Consumption - CPU + DRAM")
    plt.xlabel("Programming Languages")
    plt.ylabel("Joules")
    plt.savefig(dendogram)


def dendogram_time(data, labels):
    dendogram = os.path.join(plots_dir, "dendogram_time.png")
    linked = sch.linkage(data[:, None], method="ward")

    plt.figure(figsize=(10, 7))
    sch.dendrogram(
        linked, labels=labels, color_threshold=0, above_threshold_color="blue"
    )
    plt.title("Elapsed Time")
    plt.xlabel("Programming Languages")
    plt.ylabel("Milliseconds")
    plt.savefig(dendogram)


def dendogram_memory(data, labels):
    dendogram = os.path.join(plots_dir, "dendogram_memory.png")
    linked = sch.linkage(data[:, None], method="ward")

    plt.figure(figsize=(10, 7))
    sch.dendrogram(
        linked, labels=labels, color_threshold=0, above_threshold_color="blue"
    )
    plt.title("Total Memory Consumption")
    plt.xlabel("Programming Languages")
    plt.ylabel("Megabytes")
    plt.savefig(dendogram)


# def dendogram_peak(data, labels):
#     dendogram = os.path.join(plots_dir, "dendogram_peak.png")
#     linked = sch.linkage(data[:, None], method="ward")

#     plt.figure(figsize=(10, 7))
#     sch.dendrogram(
#         linked, labels=labels, color_threshold=0, above_threshold_color="blue"
#     )
#     plt.title("Peak Memory Consumption")
#     plt.xlabel("Programming Languages")
#     plt.ylabel("Megabytes")
#     plt.savefig(dendogram)


def dendograms(results):
    dendogram_functions = [
        dendogram_energy,
        dendogram_time,
        dendogram_memory,
        # dendogram_peak,
    ]

    if not os.path.exists(plots_dir):
        os.mkdir(plots_dir)

    for i in range(len(dendogram_functions)):
        function = dendogram_functions[i]
        data = np.array([])
        labels = []
        for language, normalized_results in results.items():
            data = np.append(data, normalized_results[i])
            labels.append(language)
        function(data, labels)


def main():
    if os.path.exists(averaged_dir):
        for algorithm in algorithms:
            averaged = os.path.join(averaged_dir, f"{algorithm}.csv")
            if os.path.exists(averaged):
                os.remove(averaged)
        os.rmdir(averaged_dir)

    global_results = {}
    for language in languages:
        rapl_results = os.path.join(language, rapl_csv)
        mem_results = os.path.join(language, mem_csv)

        if not os.path.exists(rapl_results) or not os.path.exists(mem_results):
            continue

        rapl_df = pd.read_csv(rapl_results, header=None)
        rapl_df.columns = rapl_columns

        mem_df = pd.read_csv(mem_results, header=None)
        mem_df.columns = mem_columns

        global_energy = 0
        global_time = 0
        global_memory = 0
        global_peak = 0
        for algorithm in algorithms:
            if algorithm not in list(rapl_df["Algorithm"]):
                print(f"[Error]: '{algorithm}' benchmark results not in {rapl_csv}")
                exit()
            if algorithm not in list(mem_df["Algorithm"]):
                print(f"[Error]: '{algorithm}' benchmark results not in {mem_csv}")
                exit()

            algorithm_rapl_df = rapl_df[rapl_df["Algorithm"] == algorithm][10:]
            algorithm_mem_df = mem_df[mem_df["Algorithm"] == algorithm]

            separate_results(algorithm_rapl_df, algorithm_mem_df, language, algorithm)
            energy, time, memory, peak = average_results(
                algorithm_rapl_df, algorithm_mem_df, language, algorithm
            )

            global_energy += energy
            global_time += time
            global_memory += memory
            global_peak += peak

        global_energy = global_energy / len(algorithms)
        global_time = global_time / len(algorithms)
        global_memory = global_memory / len(algorithms)
        global_peak = global_peak / len(algorithms)
        global_results[language] = (
            global_energy,
            global_time,
            global_memory,
            global_peak,
        )

    normalize_results(global_results)
    dendograms(global_results)


if __name__ == "__main__":
    main()
