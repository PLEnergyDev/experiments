from utils import read_csv_safely, calculate_energy
import pandas as pd
import argparse
import os
import re


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--rapl", nargs="+", help="One or more RAPL CSV files.")
    parser.add_argument("--perf", nargs="+", help="One or more perf text files.")
    parser.add_argument(
        "-s", "--skip", type=int, default=0, help="Number of RAPL rows to skip."
    )
    parser.add_argument(
        "-l", "--language", type=str, default="", help="Language identifier."
    )
    return parser.parse_args()


def process_perf_file(perf_file, start_time=0, end_time=float("inf")):
    metric_keys = {
        "cache-misses": "Cache Misses",
        "branch-misses": "Branch Misses",
        "LLC-loads-misses": "LLC Load Misses",
        "msr/cpu_thermal_margin/": "Cpu Thermal Margin",
        "cstate_core/c3-residency/": "C3 Residency",
        "cstate_core/c6-residency/": "C6 Residency",
        "cstate_core/c7-residency/": "C7 Residency",
    }

    parsed_data = []

    with open(perf_file, "r") as file:
        for line in file:
            parts = re.split(r"\s+", line.strip())
            if len(parts) < 2:
                continue

            metric_name = next((key for key in metric_keys if key in line), None)
            if metric_name:
                timestamp = float(parts[0])
                if not (start_time <= timestamp <= end_time):
                    continue

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

    return parsed_data


def main():
    args = parse_args()

    avg_time = 0.0
    avg_pkg = 0.0
    avg_core = 0.0
    avg_uncore = 0.0
    avg_dram = 0.0

    start_times = []
    end_times = []

    for file in args.rapl:
        df = read_csv_safely(file)
        if args.skip > 0:
            df = df.iloc[args.skip :]

        power_unit = int(file.split("_")[-1].split(".")[0])
        pkg, core, uncore, dram, time = calculate_energy(df, power_unit)

        start_time = int(time.iloc[0]) * args.skip / 1000
        end_time = int(time.iloc[-1]) * (len(time) + args.skip) / 1000
        start_times.append(start_time)
        end_times.append(end_time)

        avg_time += time.mean()
        avg_pkg += pkg.mean()
        avg_core += core.mean()
        avg_uncore += uncore.mean()
        avg_dram += dram.mean()

    num_rapl_files = len(args.rapl)
    if num_rapl_files > 0:
        avg_time /= num_rapl_files
        avg_pkg /= num_rapl_files
        avg_core /= num_rapl_files
        avg_uncore /= num_rapl_files
        avg_dram /= num_rapl_files

        averaged_rapl_data = {
            "Language": args.language,
            "Average Time (ms)": avg_time,
            "Average Pkg (J)": avg_pkg,
            "Average Core (J)": avg_core,
            "Average Uncore (J)": avg_uncore,
            "Average Dram (J)": avg_dram,
        }

        rapl_csv = "averaged_rapl.csv"
        if os.path.exists(rapl_csv):
            rapl_df = pd.read_csv(rapl_csv)
            rapl_df = pd.concat(
                [rapl_df, pd.DataFrame([averaged_rapl_data])],
                ignore_index=True,
            )
        else:
            rapl_df = pd.DataFrame([averaged_rapl_data])
        rapl_df.to_csv(rapl_csv, index=False)

    if args.perf:
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

        for i, perf_file in enumerate(args.perf):
            start_time = start_times[i] if i < len(start_times) else 0
            end_time = end_times[i] if i < len(end_times) else float("inf")

            parsed_data = process_perf_file(perf_file, start_time, end_time)

            file_metrics = {metric: [] for metric in metrics.keys()}
            for entry in parsed_data:
                for metric in metrics.keys():
                    if metric in entry:
                        file_metrics[metric].append(entry[metric])

            for metric in metrics.keys():
                if file_metrics[metric]:
                    metrics[metric].append(
                        sum(file_metrics[metric]) / len(file_metrics[metric])
                    )

        averaged_perf_data = {"Language": args.language}
        for metric in metrics.keys():
            if metrics[metric]:
                averaged_perf_data[f"Average {metric}"] = sum(metrics[metric]) / len(
                    metrics[metric]
                )
            else:
                averaged_perf_data[f"Average {metric}"] = 0

        perf_csv = "averaged_perf.csv"
        if os.path.exists(perf_csv):
            perf_df = pd.read_csv(perf_csv)
            perf_df = pd.concat(
                [perf_df, pd.DataFrame([averaged_perf_data])],
                ignore_index=True,
            )
        else:
            perf_df = pd.DataFrame([averaged_perf_data])
        perf_df.to_csv(perf_csv, index=False)


if __name__ == "__main__":
    main()
