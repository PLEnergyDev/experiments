from pathlib import Path
from utils import read_csv_safely, calculate_energy
import plotly.graph_objects as go
import argparse
import re


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("rapl", type=str)
    parser.add_argument("perf", type=str)
    parser.add_argument("-s", "--skip", type=int, default=0)
    return parser.parse_args()


def main():
    args = parse_args()
    df = read_csv_safely(args.rapl)
    if args.skip > 0:
        df = df.iloc[args.skip :]

    language = ""
    benchmark = ""

    p = Path(args.rapl)
    if len(p.parts) > 2:
        language = p.parts[-3]
        benchmark = p.parts[-2]

    power_unit = int(args.rapl.split("_")[-1].split(".")[0])
    pkg, core, uncore, dram, time = calculate_energy(df, power_unit)
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
    start_time = int(time.iloc[0]) * args.skip / 1000
    end_time = int(time.iloc[-1]) * (len(time) + args.skip) / 1000
    with open(args.perf, "r") as file:
        for line in file:
            parts = re.split(r"\s+", line.strip())
            if len(parts) < 2:
                continue

            metric_name = next((key for key in metric_keys if key in line), None)
            if metric_name:
                timestamp = float(parts[0])
                metric_key = metric_keys[metric_name]
                value = int(parts[1].replace(",", "").replace(".", ""))

                if parsed_data and metric_key not in parsed_data[-1]:
                    parsed_data[-1][metric_key] = value
                else:
                    parsed_data.append({"timestamp": timestamp, metric_key: value})

            elif "cpu-clock" in line and parsed_data:
                parsed_data[-1]["Cpu Usage"] = float(parts[5])
            elif "cycles" in line and parsed_data:
                parsed_data[-1]["Cpu Frequency"] = float(parts[4])

    clamped_data = [
        item for item in parsed_data if start_time <= item["timestamp"] <= end_time
    ]
    for item in clamped_data:
        item["timestamp"] -= start_time

    # Extract aligned data
    for entry in clamped_data:
        timestamps.append(entry["timestamp"])
        for key in metrics.keys():
            metrics[key].append(entry.get(key, 0))  # Default missing data to 0

    if not timestamps or all(len(values) == 0 for values in metrics.values()):
        return

    # --- Normalization Step (same as previous) ---
    normalized_metrics = {}
    for key, values in metrics.items():
        if values:
            vmin, vmax = min(values), max(values)
            if vmax > vmin:
                normalized_values = [(val - vmin) / (vmax - vmin) for val in values]
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
                    text=[f"{orig_val} {unit}" for orig_val in metrics[metric_name]],
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
        title=f"Interactive Metrics: <b>{language} - {benchmark}</b>",
        xaxis_title="Time (seconds)",
        yaxis_title="Count (Normalized)",
        legend_title="Metrics",
        template="plotly_white",
    )

    fig.write_html("interactive.html")


if __name__ == "__main__":
    main()
