import os
import pandas as pd

root_dir = "/home/dragon/Documents/RAPL/experiments/RAPLC/no-warmup/results"
normalized_dir = os.path.join(root_dir, "Normalized")

if not os.path.exists(normalized_dir):
    os.makedirs(normalized_dir)

languages_to_process = ["C", "C++", "Rust", "Java", "C#"]

algorithms = [
    "binary-trees",
    "fannkuch-redux",
    "fasta",
    "k-nucleotide",
    "mandelbrot",
    "n-body",
    "regex-redux",
    "reverse-complement",
    "spectral-norm",
]

output_columns = ["Language", "Energy (J)", "Time (ms)", "Ratio (J/ms)", "Memory (MB)"]




def average_results(language, algorithm, csv_file):
    df = pd.read_csv(csv_file)

    df["Total Energy (J)"] = df["Package Energy (J)"] + df["DRAM Energy (J)"]
    avg_energy = df["Total Energy (J)"].mean()
    avg_time = df["Elapsed Time (ms)"].mean()
    avg_memory = df["Total Memory (MB)"].mean()

    ratio = avg_energy / avg_time

    new_data = {
        "Language": language,
        "Energy (J)": avg_energy,
        "Time (ms)": avg_time,
        "Ratio (J/ms)": ratio,
        "Memory (MB)": avg_memory,
    }

    output_file = os.path.join(normalized_dir, f"{algorithm}.csv")

    if os.path.exists(output_file):
        normalized_df = pd.read_csv(output_file)
        normalized_df = pd.concat(
            [normalized_df, pd.DataFrame([new_data])], ignore_index=True
        )
    else:
        normalized_df = pd.DataFrame([new_data])

    normalized_df = normalized_df.round(2)

    normalized_df.to_csv(output_file, index=False, columns=output_columns)


for language in os.listdir(root_dir):
    if language in languages_to_process:
        language_path = os.path.join(root_dir, language)

        if os.path.isdir(language_path):
            for algorithm in os.listdir(language_path):
                if algorithm in algorithms:
                    algorithm_path = os.path.join(language_path, algorithm)

                    if os.path.isdir(algorithm_path):
                        csv_file = os.path.join(algorithm_path, "results.csv")

                        if os.path.exists(csv_file):
                            average_results(language, algorithm, csv_file)

print("Normalized CSV files created for each algorithm.")
