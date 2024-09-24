import re
import csv
import os

# Regular expressions to capture energy-pkg, energy-ram, and elapsed time
energy_pkg_pattern = re.compile(r"([0-9]+\.[0-9]+)\ Joules\ power/energy-pkg/")
energy_ram_pattern = re.compile(r"([0-9]+\.[0-9]+)\ Joules\ power/energy-ram/")
energy_cores_pattern = re.compile(r"([0-9]+\.[0-9]+)\ Joules\ power/energy-cores/")
elapsed_time_pattern = re.compile(r"([0-9]+\.[0-9]+)\ seconds\ time\ elapsed")

languages = [  # 7 languages
    "C",
    "C++",
    "C#",
    "Rust",
    "Java",
    # "JavaScript",
    # "Python"
]
algorithms = [  # 9 benchmarks
    "binary-trees",
    # "chameneos-redux",
    "fannkuch-redux",
    "fasta",
    "k-nucleotide",
    "mandelbrot",
    "n-body",
    # "pidigits", # Not relevant
    "regex-redux",
    "reverse-complement",
    "spectral-norm",
]
rapl_text = "rapl.txt"
rapl_csv = "rapl.csv"


def main():
    for language in languages:
        rapl_output = os.path.join(language, rapl_csv)
        for algorithm in algorithms:
            rapl_results = os.path.join(language, algorithm, rapl_text)

            if not os.path.exists(rapl_results):
                continue

            results = []

            with open(rapl_results, "r") as file:
                energy_pkg = None
                energy_ram = None
                elapsed_time = None
                energy_core = None
                energy_uncore = 0

                for line in file:
                    # Check for energy-pkg value
                    pkg_match = energy_pkg_pattern.search(line)
                    if pkg_match:
                        energy_pkg = float(pkg_match.group(1))

                    # Check for energy-ram value
                    ram_match = energy_ram_pattern.search(line)
                    if ram_match:
                        energy_ram = float(ram_match.group(1))

                    # Check for elapsed time
                    time_match = elapsed_time_pattern.search(line)
                    if time_match:
                        elapsed_time = (
                            float(time_match.group(1)) * 1000
                        )  # to get milliseconds

                    # Check for energy-cores value
                    cores_match = energy_cores_pattern.search(line)
                    if cores_match:
                        energy_core = float(cores_match.group(1))

                    # If all three values are found, store the result and reset variables
                    if (
                        energy_pkg is not None
                        and energy_ram is not None
                        and energy_core is not None
                        and elapsed_time is not None
                    ):
                        results.append(
                            [
                                algorithm,
                                energy_pkg,
                                energy_core,
                                energy_uncore,
                                energy_ram,
                                elapsed_time,
                            ]
                        )
                        energy_pkg = None  # Reset for next iteration
                        energy_ram = None
                        energy_core = None
                        elapsed_time = None

            # Write the results to the CSV file
            with open(rapl_output, "a", newline="") as csvfile:
                csvwriter = csv.writer(csvfile)
                # Write header
                csvwriter.writerows(results)


if __name__ == "__main__":
    main()
