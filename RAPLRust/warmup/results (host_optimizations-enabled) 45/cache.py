import os
import re
import matplotlib.pyplot as plt

# Define languages and algorithms
languages = ["C", "C++", "C#", "Rust", "Java"]
algorithms = [
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
cache_txt = "cache.txt"


def parse_results(results_path):
    """
    Parse cache data from the results file.
    """
    timestamps = []
    metrics = {
        # "Cache Misses": [],
        # "Cache References": [],
        "LLC Load Misses": [],
        # "LLC Loads": [],
    }

    # Temporary storage to track which timestamp matches each metric
    parsed_data = []

    with open(results_path, "r") as file:
        for line in file:
            parts = re.split(r"\s+", line.strip())
            if len(parts) < 2:
                continue
            if "cache-misses" in line:
                parsed_data.append({"timestamp": float(parts[0]), "Cache Misses": int(parts[1].replace(",", "").replace(".", ""))})
            elif "cache-references" in line:
                if parsed_data and "Cache References" not in parsed_data[-1]:
                    parsed_data[-1]["Cache References"] = int(parts[1].replace(",", "").replace(".", ""))
            elif "LLC-loads-misses" in line:
                if parsed_data and "LLC Load Misses" not in parsed_data[-1]:
                    parsed_data[-1]["LLC Load Misses"] = int(parts[1].replace(",", "").replace(".", ""))
            elif "LLC-loads" in line:
                if parsed_data and "LLC Loads" not in parsed_data[-1]:
                    parsed_data[-1]["LLC Loads"] = int(parts[1].replace(",", "").replace(".", ""))

    # Extract aligned data
    for entry in parsed_data:
        timestamps.append(entry["timestamp"])
        for key in metrics.keys():
            metrics[key].append(entry.get(key, 0))  # Default missing data to 0

    return timestamps, metrics

def downsample_data(timestamps, metrics, step=10):
    """
    Downsample data to reduce the number of points.
    Args:
        timestamps: List of timestamps.
        metrics: Dictionary of metric lists.
        step: Interval for selecting points (e.g., every `step` points).
    Returns:
        Downsampled timestamps and metrics.
    """
    downsampled_timestamps = timestamps[::step]
    downsampled_metrics = {key: values[::step] for key, values in metrics.items()}
    return downsampled_timestamps, downsampled_metrics

def plot(language, algorithm, results_path):
    """
    Plot cache metrics for a given language and algorithm.
    """
    timestamps, metrics = parse_results(results_path)

    timestamps, metrics = downsample_data(timestamps, metrics, step=10)

    # Skip if there is no data
    if not timestamps or all(len(values) == 0 for values in metrics.values()):
        print(f"No valid data for {language} - {algorithm}")
        return

    # Plot the metrics
    plt.figure(figsize=(12, 6))
    for key, values in metrics.items():
        if values:  # Only plot if data exists
            plt.plot(timestamps, values, label=key, marker="o")

    # Save the figure
    os.makedirs("Plots", exist_ok=True)
    figure_path = os.path.join("Plots", f"{language}_{algorithm}_cache.png")
    plt.xlabel("Time (seconds)")
    plt.ylabel("Count")
    plt.title(f"Cache Metrics Over Time: {language} - {algorithm}")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(figure_path)
    plt.close()
    print(f"Plot saved: {figure_path}")


def main():
    """
    Main function to iterate over languages and algorithms and plot cache metrics.
    """
    for language in languages:
        for algorithm in algorithms:
            results_path = os.path.join(language, algorithm, cache_txt)

            if not os.path.exists(results_path):
                print(f"Results file not found: {results_path}")
                continue

            plot(language, algorithm, results_path)


if __name__ == "__main__":
    main()
