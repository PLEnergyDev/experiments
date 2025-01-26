import pandas as pd
import numpy as np
import seaborn as sns
import scipy.cluster.hierarchy as sch
import matplotlib.pyplot as plt
import argparse
import os
import re
import shutil
import plotly.graph_objects as go

BENCHMARK_LANGUAGES = ["C", "C++", "C#", "Java", "Rust"]
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
RESULTS_DIR = "results_prod_20-01-2025"


def compile(benchmark):
    for lang in BENCHMARK_LANGUAGES:
        lang_dir = os.path.join(benchmark, RESULTS_DIR, lang)

        lang_data = []
        for bench in BENCHMARKS:
            bench_results = os.path.join(lang_dir, bench, "rapl.csv")

            if not os.path.exists(bench_results):
                print(
                    f"[WARNING] Missing benchmark results '{bench_results}'. Skipping."
                )
                continue

            # print(f"[INFO] {bench_results}")
            bench_df = pd.read_csv(bench_results, header=0, comment="T")
            pkg = (bench_df.iloc[:, 7] - bench_df.iloc[:, 6]) * 6.103515625e-05
            core = (bench_df.iloc[:, 3] - bench_df.iloc[:, 2]) * 6.103515625e-05
            uncore = (bench_df.iloc[:, 5] - bench_df.iloc[:, 4]) * 6.103515625e-05
            dram = (bench_df.iloc[:, 9] - bench_df.iloc[:, 8]) * 6.103515625e-05
            time = bench_df.iloc[:, 1] - bench_df.iloc[:, 0]

            for i in range(len(bench_df)):
                lang_data.append([bench, pkg[i], core[i], uncore[i], dram[i], time[i]])

        if lang_data:
            lang_results = os.path.join(lang_dir, "rapl.csv")
            lang_df = pd.DataFrame(lang_data)
            lang_df.to_csv(lang_results, header=False, index=False)


def average_results(benchmark, skip=15):
    averaged_dir = os.path.join(benchmark, RESULTS_DIR, "averaged")
    if os.path.exists(averaged_dir):
        shutil.rmtree(averaged_dir)
    os.mkdir(averaged_dir)

    for lang in BENCHMARK_LANGUAGES:
        lang_results = os.path.join(benchmark, RESULTS_DIR, lang, "rapl.csv")
        if not os.path.exists(lang_results):
            print(
                f"[WARNING] Missing compiled language results '{lang_results}'. Skipping."
            )
            continue

        lang_df = pd.read_csv(lang_results, header=None)
        lang_df.columns = RAPL_COLUMNS
        for bench in BENCHMARKS:
            if bench not in list(lang_df["Algorithm"]):
                print(
                    f"[WARNING] Missing benchmark results in compiled language results '{lang_results}'. Skipping."
                )
                continue

            averaged_results = os.path.join(
                benchmark, RESULTS_DIR, "averaged", f"{bench}.csv"
            )

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


def normalize_results(benchmark, skip=15):
    energy = 0
    time = 0
    normalized_dict = {}
    normalized_result = os.path.join(benchmark, RESULTS_DIR, "normalized.csv")
    for lang in BENCHMARK_LANGUAGES:
        lang_results = os.path.join(benchmark, RESULTS_DIR, lang, "rapl.csv")
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

    normalized_df["Normalized Energy (J)"] = normalized_df["Energy (J)"] / min_energy
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


def dendrograms(benchmark):
    dendrogram_functions = [
        _dendrogram_energy,
        _dendrogram_time,
    ]

    energy = 0
    time = 0
    normalized_dict = {}
    for lang in BENCHMARK_LANGUAGES:
        lang_results = os.path.join(benchmark, RESULTS_DIR, lang, "rapl.csv")
        if not os.path.exists(lang_results):
            print(
                f"[ERROR] Missing compiled language results '{lang_results}'. Exiting."
            )
            continue

        lang_df = pd.read_csv(lang_results, header=None)
        lang_df.columns = RAPL_COLUMNS
        for bench in BENCHMARKS:
            if bench not in list(lang_df["Algorithm"]):
                print(
                    f"[ERROR] Missing benchmark results in compiled language results '{lang_results}'. Exiting."
                )
                continue

            bench_df = lang_df[lang_df["Algorithm"] == bench]
            energy_df = bench_df["Package Energy (J)"] + bench_df["DRAM Energy (J)"]
            time_df = bench_df["Elapsed Time (ms)"]

            energy += energy_df.mean()
            time += time_df.mean()

        energy = energy / len(BENCHMARKS)
        time = time / len(BENCHMARKS)

        normalized_dict[lang] = (energy, time)

    plots_dir = os.path.join(benchmark, RESULTS_DIR, "plots", "dendrograms")
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


def violins(benchmark):
    plots_dir = os.path.join(benchmark, RESULTS_DIR, "plots", "violins")
    if not os.path.exists(plots_dir):
        os.makedirs(plots_dir)

    for lang in BENCHMARK_LANGUAGES:
        lang_results = os.path.join(benchmark, RESULTS_DIR, lang, "rapl.csv")
        if not os.path.exists(lang_results):
            print(
                f"[WARNING] Missing compiled language results '{lang_results}'. Skipping."
            )
            continue

        lang_df = pd.read_csv(lang_results, header=None)
        lang_df.columns = RAPL_COLUMNS

        for bench in BENCHMARKS:
            if bench not in list(lang_df["Algorithm"]):
                print(
                    f"[WARNING] Missing benchmark '{bench}' in '{lang_results}'. Skipping."
                )
                continue

            # Filter the DataFrame for the current benchmark
            if os.path.basename(benchmark) == "warmup":
                bench_df = lang_df[lang_df["Algorithm"] == bench][15:]
            else:
                bench_df = lang_df[lang_df["Algorithm"] == bench]

            rows = ["Package Energy (J)", "DRAM Energy (J)", "Elapsed Time (ms)"]

            fig, axs = plt.subplots(
                nrows=len(rows),
                ncols=2,  # One violin plot and one box plot per row
                figsize=(10, len(rows) * 5),
                sharey="row",
            )
            fig.subplots_adjust(hspace=0.4, wspace=0.4)

            for row_i, row in enumerate(rows):
                # Plot violin plot
                sns.violinplot(
                    y=row,
                    data=bench_df,
                    ax=axs[row_i, 0],
                )
                axs[row_i, 0].set_title(f"{row} (Violin Plot)")
                axs[row_i, 0].set_ylabel(row)
                axs[row_i, 0].set_xlabel(bench)

                # Plot box plot
                sns.boxplot(
                    y=row,
                    data=bench_df,
                    ax=axs[row_i, 1],
                )
                axs[row_i, 1].set_title(f"{row} (Box Plot)")
                axs[row_i, 1].set_ylabel(row)
                axs[row_i, 1].set_xlabel(bench)

            lang_dir = os.path.join(plots_dir, lang)
            if not os.path.exists(lang_dir):
                os.makedirs(lang_dir)

            violin_result = os.path.join(lang_dir, f"{bench}.png")
            plt.tight_layout()
            plt.savefig(violin_result)
            plt.close()
            print(f"[INFO] Saved violin plots for {lang} - {bench} at {violin_result}")


def interactive_caches(benchmark, step=1):
    plots_dir = os.path.join(benchmark, RESULTS_DIR, "plots", "interactive_caches")
    if not os.path.exists(plots_dir):
        os.makedirs(plots_dir)

    for lang in BENCHMARK_LANGUAGES:
        lang_results = os.path.join(benchmark, RESULTS_DIR, lang, "rapl.csv")
        if not os.path.exists(lang_results):
            print(
                f"[WARNING] Missing compiled language results '{lang_results}'. Skipping."
            )
            continue
        lang_df = pd.read_csv(lang_results, header=None)
        lang_df.columns = RAPL_COLUMNS

        for bench in BENCHMARKS:
            bench_results = os.path.join(
                benchmark, RESULTS_DIR, lang, bench, "cache.txt"
            )
            if not os.path.exists(bench_results) or bench not in list(
                lang_df["Algorithm"]
            ):
                print(
                    f"[WARNING] Missing benchmark results in '{bench_results}'. Skipping."
                )
                continue

            timestamps = []
            metrics = {
                "Cache Misses": [],
                "Branch Misses": [],
                "LLC Load Misses": [],
                "Cpu Thermal Margin": [],
                "Cpu Usage": [],
                "Cpu Frequency": [],
                "C3 Residency": [],
                "C6 Residency": [],
                "C7 Residency": [],
            }
            metric_keys = {
                "cache-misses": "Cache Misses",
                "branch-misses": "Banch Misses",
                "LLC-loads-misses": "LLC Load Misses",
                "msr/cpu_thermal_margin/": "Cpu Thermal Margin",
                "cstate_core/c3-residency/": "C3 Residency",
                "cstate_core/c6-residency/": "C6 Residency",
                "cstate_core/c7-residency/": "C7 Residency",
            }
            metric_units = {
                "Cache Misses": "misses",
                "Branch Misses": "misses",
                "LLC Load Misses": "misses",
                "Cpu Thermal Margin": "°C",
                "Cpu Usage": "CPUs",
                "Cpu Frequency": "GHz",
                "C3 Residency": "count",
                "C6 Residency": "count",
                "C7 Residency": "count",
            }
            color_map = {
                "Cache Misses": "darkorange",
                "Branch Misses": "goldenrod",
                "LLC Load Misses": "sandybrown",
                "Cpu Thermal Margin": "mediumpurple",
                "Cpu Usage": "limegreen",
                "Cpu Frequency": "mediumseagreen",
                "C3 Residency": "royalblue",
                "C6 Residency": "dodgerblue",
                "C7 Residency": "steelblue",
            }
            parsed_data = []

            with open(bench_results, "r") as file:
                for line in file:
                    parts = re.split(r"\s+", line.strip())
                    if len(parts) < 2:
                        continue

                    metric_name = next(
                        (key for key in metric_keys if key in line), None
                    )
                    if metric_name:
                        timestamp = float(parts[0])
                        metric_key = metric_keys[metric_name]
                        value = int(parts[1].replace(",", "").replace(".", ""))

                        if parsed_data and metric_key not in parsed_data[-1]:
                            parsed_data[-1][metric_key] = value
                        else:
                            parsed_data.append(
                                {"timestamp": timestamp, metric_key: value}
                            )
                    elif "cpu-clock" in line:
                        if parsed_data and "Cpu Usage" not in parsed_data[-1]:
                            parsed_data[-1]["Cpu Usage"] = float(parts[5])
                    elif "cycles" in line:
                        if parsed_data and "Cpu Frequency" not in parsed_data[-1]:
                            parsed_data[-1]["Cpu Frequency"] = float(parts[4])

            # Extract aligned data
            for entry in parsed_data:
                timestamps.append(entry["timestamp"])
                for key in metrics.keys():
                    metrics[key].append(entry.get(key, 0))  # Default missing data to 0

            timestamps = timestamps[::step]
            metrics = {key: values[::step] for key, values in metrics.items()}

            # Skip if there is no data
            if not timestamps or all(len(values) == 0 for values in metrics.values()):
                print(f"No valid data for {lang} - {bench}")
                continue

            # --- Normalization Step (same as previous) ---
            normalized_metrics = {}
            for key, values in metrics.items():
                if values:
                    vmin, vmax = min(values), max(values)
                    if vmax > vmin:
                        normalized_values = [
                            (val - vmin) / (vmax - vmin) for val in values
                        ]
                    else:
                        normalized_values = values
                    normalized_metrics[key] = normalized_values
                else:
                    normalized_metrics[key] = values
            # ---------------------------------------------

            # Create an interactive plot
            fig = go.Figure()

            # Plot all metrics using normalized values
            for metric_name, values in metrics.items():
                if values:
                    raw_avg = sum(values) / len(values)
                    vmin, vmax = min(values), max(values)
                    if vmax > vmin:
                        normalized_avg = (raw_avg - vmin) / (vmax - vmin)
                    else:
                        normalized_avg = raw_avg

                    line_color = color_map.get(metric_name, "black")
                    unit = metric_units.get(metric_name, "")

                    # Add main metric line
                    fig.add_trace(
                        go.Scatter(
                            x=timestamps,
                            y=normalized_metrics[metric_name],
                            mode="lines+markers",
                            name=metric_name,
                            line=dict(shape="spline", color=line_color),
                            text=[
                                f"{orig_val} {unit}"
                                for orig_val in metrics[metric_name]
                            ],
                            hovertemplate=(
                                "Timestamp: <b>%{x}</b><br>"
                                "Original: <b>%{text}</b><extra></extra>"
                            ),
                            legendgroup=metric_name,  # Group with the average line
                        )
                    )

                    # Add corresponding average line
                    fig.add_trace(
                        go.Scatter(
                            x=[timestamps[0], timestamps[-1]],  # Horizontal line
                            y=[normalized_avg, normalized_avg],
                            mode="lines",
                            name=f"Avg {metric_name}",
                            line=dict(color=line_color, dash="dot"),
                            legendgroup=metric_name,  # Link to the main metric plot
                            showlegend=False,  # Hide in legend (but it toggles with the main plot)
                        )
                    )
                    # Add text label as a scatter trace
                    fig.add_trace(
                        go.Scatter(
                            y=[normalized_avg],
                            mode="text",
                            text=[f"Avg {metric_name}: {raw_avg:.2f} {unit}"],
                            textposition="top left",
                            showlegend=False,  # Don't show in legend
                            legendgroup=metric_name,  # Hide when metric is toggled
                        )
                    )

            bench_df = lang_df[lang_df["Algorithm"] == bench]
            pkg = bench_df["Package Energy (J)"]
            dram = bench_df["DRAM Energy (J)"]
            time = bench_df["Elapsed Time (ms)"]

            # Plot vertical lines for each measured iteration within the x-axis range
            max_timestamp = max(timestamps) if timestamps else 0
            time_sum = 0
            for pkg_end, dram_end, time_end in zip(pkg, dram, time):
                time_end = time_end / 1000
                time_sum += time_end

                pkg_end = round(pkg_end, 2)
                dram_end = round(dram_end, 2)
                time_sum = round(time_sum, 2)
                time_end = round(time_end, 2)

                if time_sum <= max_timestamp:
                    fig.add_vline(
                        x=time_sum,
                        line=dict(color="red", dash="dash"),
                        annotation_text=(
                            f"PKG: <b>{pkg_end} J</b><br>"
                            f"DRAM: <b>{dram_end} J</b><br>"
                            f"TIME: <b>{time_end} s</b>"
                        ),
                        annotation_position="top left",
                    )

            # Customize layout
            fig.update_layout(
                title=f"Interactive Metrics: <b>{os.path.basename(benchmark)} - {lang} - {bench}</b>",
                xaxis_title="Time (seconds)",
                yaxis_title="Count (Normalized)",
                legend_title="Metrics",
                template="plotly_white",
            )

            # Ensure the language-specific directory exists
            lang_dir = os.path.join(plots_dir, lang)
            if not os.path.exists(lang_dir):
                os.makedirs(lang_dir)

            # Save the interactive HTML file
            html_path = os.path.join(lang_dir, f"{bench}.html")
            fig.write_html(html_path)
            print(f"[INFO] Interactive plot saved to: {html_path}")


def caches(benchmark, step=1):
    plots_dir = os.path.join(benchmark, RESULTS_DIR, "plots", "caches")
    if not os.path.exists(plots_dir):
        os.makedirs(plots_dir)

    for lang in BENCHMARK_LANGUAGES:
        lang_results = os.path.join(benchmark, RESULTS_DIR, lang, "rapl.csv")
        if not os.path.exists(lang_results):
            print(
                f"[WARNING] Missing compiled language results '{lang_results}'. Skipping."
            )
            continue
        lang_df = pd.read_csv(lang_results, header=None)
        lang_df.columns = RAPL_COLUMNS

        for bench in BENCHMARKS:
            bench_results = os.path.join(
                benchmark, RESULTS_DIR, lang, bench, "cache.txt"
            )
            if not os.path.exists(bench_results) or bench not in list(
                lang_df["Algorithm"]
            ):
                print(
                    f"[WARNING] Missing benchmark results in '{bench_results}'. Skipping."
                )
                continue

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
                        if parsed_data and "Cache References" not in parsed_data[-1]:
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
                    metrics[key].append(entry.get(key, 0))  # Default missing data to 0

            timestamps = timestamps[::step]
            metrics = {key: values[::step] for key, values in metrics.items()}

            # Skip if there is no data
            if not timestamps or all(len(values) == 0 for values in metrics.values()):
                print(f"No valid data for {lang} - {bench}")
                return

            # Plot the metrics
            plt.figure(figsize=(12, 6))
            for key, values in metrics.items():
                if values:  # Only plot if data exists
                    plt.plot(timestamps, values, label=key, marker="o")

            bench_df = lang_df[lang_df["Algorithm"] == bench]
            time = bench_df["Elapsed Time (ms)"]

            # for time_end in time:
            #     plt.axvline(x=time_end, color="red", linestyle="--")
            # Get max timestamp from the data for comparison
            max_timestamp = max(timestamps) if timestamps else 0

            # Plot vertical lines for each measured iteration within the x-axis range
            time_sum = 0
            for time_end in time:
                time_end_sec = time_end / 1000  # Convert ms to seconds
                time_sum += time_end_sec
                if time_sum <= max_timestamp:
                    plt.axvline(x=time_sum, color="red", linestyle="--")

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


def handle_command(args):
    if not os.path.exists(args.benchmarks_dir):
        print(f"[ERROR] Benchmark directory '{args.benchmarks_dir}' does not exist.")
        return

    benchmark = os.path.join(args.benchmarks_dir, args.command)

    print(f"[INFO] Compiling benchmark results...")
    compile(benchmark)

    if args.average_results:
        print(f"[INFO] Averaging results...")
        average_results(benchmark)

    if args.normalize_results:
        print(f"[INFO] Normalizing results...")
        normalize_results(benchmark)

    if args.dendrograms:
        print(f"[INFO] Plotting dendrograms...")
        dendrograms(benchmark)

    if args.violins:
        print(f"[INFO] Plotting violins...")
        violins(benchmark)

    if args.caches:
        print(f"[INFO] Plotting caches...")
        caches(benchmark)

    if args.interactive_caches:
        print(f"[INFO] Plotting interactive caches...")
        interactive_caches(benchmark)

    print(f"[INFO] Done!")


def parse_args():
    parser = argparse.ArgumentParser(description="Benchmark processing script.")
    parser.add_argument(
        "--benchmarks-dir",
        type=str,
        required=True,
        help="Directory where the benchmarks are located.",
    )

    subparsers = parser.add_subparsers(
        dest="command", required=True, help="Available commands"
    )

    parser_warmup = subparsers.add_parser("warmup", help="Process warmup benchmarks.")
    parser_warmup.add_argument(
        "-a", "--average-results", action="store_true", help="Average results."
    )
    parser_warmup.add_argument(
        "-n", "--normalize-results", action="store_true", help="Normalize results."
    )
    parser_warmup.add_argument(
        "-d", "--dendrograms", action="store_true", help="Generate dendrograms."
    )
    parser_warmup.add_argument(
        "-v", "--violins", action="store_true", help="Generate violin plots."
    )
    parser_warmup.add_argument(
        "-c", "--caches", action="store_true", help="Generate cache plots."
    )
    parser_warmup.add_argument(
        "-i",
        "--interactive-caches",
        action="store_true",
        help="Generate interactive cache plots.",
    )

    parser_no_warmup = subparsers.add_parser(
        "no-warmup", help="Process no-warmup benchmarks."
    )
    parser_no_warmup.add_argument(
        "-a", "--average-results", action="store_true", help="Average results."
    )
    parser_no_warmup.add_argument(
        "-n", "--normalize-results", action="store_true", help="Normalize results."
    )
    parser_no_warmup.add_argument(
        "-d", "--dendrograms", action="store_true", help="Generate dendrograms."
    )
    parser_no_warmup.add_argument(
        "-v", "--violins", action="store_true", help="Generate violin plots."
    )
    parser_no_warmup.add_argument(
        "-c", "--caches", action="store_true", help="Generate cache plots."
    )
    parser_no_warmup.add_argument(
        "-i",
        "--interactive-caches",
        action="store_true",
        help="Generate interactive cache plots.",
    )

    return parser.parse_args()


def main():
    args = parse_args()
    handle_command(args)


if __name__ == "__main__":
    main()
