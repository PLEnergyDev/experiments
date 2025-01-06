import pandas as pd
import seaborn as sns
import os

import matplotlib.pyplot as plt

sns.set(style="whitegrid")

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
rapl_columns = [
    "Algorithm",
    "Package Energy (J)",
    "Core Energy (J)",
    "Uncore Energy (J)",
    "DRAM Energy (J)",
    "Elapsed Time (ms)",
]
results_csv = "results.csv"


def plot(language, algorith, results_path):
    rows = rapl_columns[1:]
    experiments = {
        "RAPLRust Warmup": {
            f"{language} {algorith}": results_path,
        }
    }
    fig, axs = plt.subplots(
        nrows=len(rows),
        ncols=len(experiments) * 2,
        figsize=(len(experiments) * 15, len(rows) * 5),
        sharey="row",
    )
    fig.subplots_adjust(hspace=0.4, wspace=0.4)

    for exp_i, (experiment_name, conditions) in enumerate(experiments.items()):
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
                    x="Condition", y=row, data=combined_data, ax=axs[violin_ax_index]
                )

                # Plot box plot
                sns.boxplot(
                    x="Condition", y=row, data=combined_data, ax=axs[box_ax_index]
                )

                # Set titles
                axs[violin_ax_index].set_title(row)
                axs[box_ax_index].set_title(row)
                axs[violin_ax_index].set_xlabel(experiment_name)
                axs[box_ax_index].set_xlabel(experiment_name)

    figure_path = os.path.join("Plots", f"{language}_{algorith}.png")
    plt.tight_layout()
    plt.savefig(figure_path)
    plt.close()


def main():
    for language in languages:
        for algorithm in algorithms:
            results_path = os.path.join(language, algorithm, results_csv)

            if not os.path.exists(results_path):
                continue

            plot(language, algorithm, results_path)


if __name__ == "__main__":
    main()
