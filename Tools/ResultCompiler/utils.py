import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import plotly.graph_objects as go

import shutil
import re
import os


class Compiler:
    def __init__(self, base_dir, configs, languages, benchmarks):
        self.base_dir = base_dir
        self.languages = languages
        self.benchmarks = benchmarks
        self.configs = configs

        self.rapl_columns = [
            "Algorithm",
            "Package Energy (J)",
            "Core Energy (J)",
            "Uncore Energy (J)",
            "DRAM Energy (J)",
            "Elapsed Time (ms)",
        ]
        self.average_columns = ["Language", "Energy (J)", "Time (ms)", "Ratio (J/ms)"]
        self.normalize_columns = ["Energy (J)", "Time (ms)"]

    def read_csv_safely(self, path):
        """Read CSV file if it exists, otherwise return None."""
        if not os.path.exists(path):
            return None
        return pd.read_csv(path, header=0, comment="T")

    def calculate_energy(self, df):
        """Calculate energy consumption from raw data."""
        pkg = (df.iloc[:, 7] - df.iloc[:, 6]) * 6.103515625e-05
        core = (df.iloc[:, 3] - df.iloc[:, 2]) * 6.103515625e-05
        uncore = (df.iloc[:, 5] - df.iloc[:, 4]) * 6.103515625e-05
        dram = (df.iloc[:, 9] - df.iloc[:, 8]) * 6.103515625e-05
        time = df.iloc[:, 1] - df.iloc[:, 0]
        return pkg, core, uncore, dram, time

    def compile(self):
        for config in self.configs:
            config_dir = os.path.join(self.base_dir, config)
            if not os.path.exists(config_dir):
                continue

            for lang in self.languages:
                lang_dir = os.path.join(config_dir, lang)
                if not os.path.exists(lang_dir):
                    continue

                data = []
                for bench in self.benchmarks:
                    result_csv = os.path.join(lang_dir, bench, "rapl.csv")
                    df = self.read_csv_safely(result_csv)
                    if df is None:
                        continue

                    pkg, core, uncore, dram, time = self.calculate_energy(df)
                    for i in range(len(pkg)):
                        data.append(
                            [bench, pkg[i], core[i], uncore[i], dram[i], time[i]]
                        )

                if data:
                    lang_csv = os.path.join(lang_dir, "rapl.csv")
                    df = pd.DataFrame(data)
                    df.to_csv(lang_csv, header=False, index=False)

    def average(self, skip=15):
        for config in self.configs:
            config_dir = os.path.join(self.base_dir, config)
            if not os.path.exists(config_dir):
                continue

            average_dir = os.path.join(config_dir, "average")

            if os.path.exists(average_dir):
                shutil.rmtree(average_dir)
            os.mkdir(average_dir)

            for lang in self.languages:
                lang_dir = os.path.join(config_dir, lang)
                if not os.path.exists(lang_dir):
                    continue

                lang_csv = os.path.join(lang_dir, "rapl.csv")
                lang_df = self.read_csv_safely(lang_csv)
                if lang_df is None:
                    continue

                lang_df.columns = self.rapl_columns

                for bench in self.benchmarks:
                    average_csv = os.path.join(average_dir, f"{bench}.csv")
                    bench_df = lang_df[lang_df["Algorithm"] == bench][skip:]

                    energy = (
                        bench_df["Package Energy (J)"] + bench_df["DRAM Energy (J)"]
                    )
                    time = bench_df["Elapsed Time (ms)"]
                    avg_energy = energy.mean()
                    avg_time = time.mean()
                    ratio = avg_energy / avg_time if avg_time > 0 else 0

                    averaged_data = {
                        "Language": lang,
                        "Energy (J)": avg_energy,
                        "Time (ms)": avg_time,
                        "Ratio (J/ms)": ratio,
                    }

                    if os.path.exists(average_csv):
                        results_df = pd.read_csv(average_csv)
                        results_df = pd.concat(
                            [results_df, pd.DataFrame([averaged_data])],
                            ignore_index=True,
                        )
                    else:
                        results_df = pd.DataFrame([averaged_data])

                    results_df.to_csv(average_csv, index=False)

    def normalize(self, skip=15):
        for config in self.configs:
            config_dir = os.path.join(self.base_dir, config)
            if not os.path.exists(config_dir):
                continue

            normalize_dict = {}
            normalize_csv = os.path.join(config_dir, "normalized.csv")

            if os.path.exists(normalize_csv):
                os.remove(normalize_csv)

            for lang in self.languages:
                lang_dir = os.path.join(config_dir, lang)
                if not os.path.exists(lang_dir):
                    continue

                lang_csv = os.path.join(lang_dir, "rapl.csv")
                lang_df = self.read_csv_safely(lang_csv)
                if lang_df is None:
                    continue

                lang_df.columns = self.rapl_columns

                energy_total, time_total = 0, 0
                if len(self.benchmarks) == 0:
                    continue

                for bench in self.benchmarks:
                    bench_df = lang_df[lang_df["Algorithm"] == bench][skip:]
                    if bench_df.empty:
                        continue

                    energy_total += (
                        bench_df["Package Energy (J)"] + bench_df["DRAM Energy (J)"]
                    ).mean()
                    time_total += bench_df["Elapsed Time (ms)"].mean()

                avg_energy = (
                    energy_total / len(self.benchmarks) if energy_total > 0 else 0
                )
                avg_time = time_total / len(self.benchmarks) if time_total > 0 else 0
                normalize_dict[lang] = (avg_energy, avg_time)

            normalized_df = (
                pd.DataFrame.from_dict(
                    normalize_dict, orient="index", columns=self.normalize_columns
                )
                .reset_index()
                .rename(columns={"index": "Language"})
            )

            if normalized_df.empty:
                continue

            # Compute normalization factors
            min_energy = normalized_df["Energy (J)"].min()
            min_time = normalized_df["Time (ms)"].min()

            normalized_df["Normalized Energy (J)"] = (
                normalized_df["Energy (J)"] / min_energy if min_energy > 0 else 1
            )
            normalized_df["Normalized Time (ms)"] = (
                normalized_df["Time (ms)"] / min_time if min_time > 0 else 1
            )

            normalized_df.to_csv(normalize_csv, index=False)

    def violins(self):
        for config in self.configs:
            config_dir = os.path.join(self.base_dir, config)

            for lang in self.languages:
                lang_dir = os.path.join(config_dir, lang)
                if not os.path.exists(lang_dir):
                    continue

                plots_dir = os.path.join(lang_dir, "plots", "violins")
                if not os.path.exists(plots_dir):
                    os.makedirs(plots_dir)

                lang_csv = os.path.join(lang_dir, "rapl.csv")
                lang_df = self.read_csv_safely(lang_csv)
                if lang_df is None:
                    continue

                lang_df.columns = self.rapl_columns

                for bench in self.benchmarks:
                    if bench not in lang_df["Algorithm"].values:
                        continue

                    bench_df = lang_df[lang_df["Algorithm"] == bench]

                    rows = [
                        "Package Energy (J)",
                        "DRAM Energy (J)",
                        "Elapsed Time (ms)",
                    ]

                    fig, axs = plt.subplots(
                        nrows=len(rows),
                        ncols=2,
                        figsize=(10, len(rows) * 5),
                        sharey="row",
                    )
                    fig.subplots_adjust(hspace=0.4, wspace=0.4)

                    for row_i, row in enumerate(rows):
                        # Violin plot
                        sns.violinplot(y=row, data=bench_df, ax=axs[row_i, 0])
                        axs[row_i, 0].set_title(f"{row} (Violin Plot)")
                        axs[row_i, 0].set_ylabel(row)
                        axs[row_i, 0].set_xlabel(bench)

                        # Box plot
                        sns.boxplot(y=row, data=bench_df, ax=axs[row_i, 1])
                        axs[row_i, 1].set_title(f"{row} (Box Plot)")
                        axs[row_i, 1].set_ylabel(row)
                        axs[row_i, 1].set_xlabel(bench)

                    violin_result = os.path.join(plots_dir, f"{bench}.png")
                    plt.tight_layout()
                    plt.savefig(violin_result)
                    plt.close()

    def interactive(self):
        """Generate interactive HTML plots for benchmarks."""
        for config in self.configs:
            config_dir = os.path.join(self.base_dir, config)
            if not os.path.exists(config_dir):
                continue

            for lang in self.languages:
                lang_dir = os.path.join(config_dir, lang)
                if not os.path.exists(lang_dir):
                    continue

                plots_dir = os.path.join(lang_dir, "plots", "interactive")
                if not os.path.exists(plots_dir):
                    os.makedirs(plots_dir)

                lang_csv = os.path.join(lang_dir, "rapl.csv")
                lang_df = self.read_csv_safely(lang_csv)
                if lang_df is None:
                    continue

                lang_df.columns = self.rapl_columns

                for bench in self.benchmarks:
                    bench_results = os.path.join(lang_dir, bench, "cache.txt")
                    if (
                        not os.path.exists(bench_results)
                        or bench not in lang_df["Algorithm"].values
                    ):
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
                        "branch-misses": "Branch Misses",
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

                            elif "cpu-clock" in line and parsed_data:
                                parsed_data[-1]["Cpu Usage"] = float(parts[5])
                            elif "cycles" in line and parsed_data:
                                parsed_data[-1]["Cpu Frequency"] = float(parts[4])

                    # Extract aligned data
                    for entry in parsed_data:
                        timestamps.append(entry["timestamp"])
                        for key in metrics.keys():
                            metrics[key].append(
                                entry.get(key, 0)
                            )  # Default missing data to 0

                    if not timestamps or all(
                        len(values) == 0 for values in metrics.values()
                    ):
                        continue  # Skip empty data

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
                                    x=[
                                        timestamps[0],
                                        timestamps[-1],
                                    ],  # Horizontal line
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
                        title=f"Interactive Metrics: <b>{config} - {lang} - {bench}</b>",
                        xaxis_title="Time (seconds)",
                        yaxis_title="Count (Normalized)",
                        legend_title="Metrics",
                        template="plotly_white",
                    )

                    html_path = os.path.join(plots_dir, f"{bench}.html")
                    fig.write_html(html_path)
