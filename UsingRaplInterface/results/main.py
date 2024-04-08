import pandas as pd
import os
import glob

dirs = ["C", "C#", "Java"]
algorithms = ["DivisionLoop", "FannkuchRedux", "Mandelbrot", "MatrixMultiplication", "MatrixMultiplicationUnsafe", "NBody", "Pidigits", "PolynomialEvaluation", "SpectralNorm"]

def calculate_package_energy(csv_file_path):
    """
    Calculate "Elapsed Time (ms)", "Package Energy (µJ)", and "DRAM Energy (µJ)" for a given CSV file.
    Also, splits the data into no warmup and warmup portions and saves these separately.
    """
    # Load the CSV file
    df = pd.read_csv(csv_file_path)

    # Create a new DataFrame with the calculated columns
    calculations_df = pd.DataFrame({
        'Elapsed Time (ms)': df['TimeEnd'] - df['TimeStart'],
        'Package Energy (µJ)': (df['PkgEnd'] - df['PkgStart']) * 61.03515625,
        'DRAM Energy (µJ)': (df['DramEnd'] - df['DramStart']) * 61.03515625
    })

    # Splitting the data for no warmup and warmup
    no_warmup_df = calculations_df.head(500)
    warmup_df = calculations_df.tail(500)

    # Save no warmup data
    no_warmup_file_path = csv_file_path.replace('.csv', '_no_warmup.csv')
    no_warmup_df.to_csv(no_warmup_file_path, index=False, sep=";")
    print(f"Processed and saved no warmup data: {no_warmup_file_path}")

    # Save warmup data
    warmup_file_path = csv_file_path.replace('.csv', '_warmup.csv')
    warmup_df.to_csv(warmup_file_path, index=False, sep=";")
    print(f"Processed and saved warmup data: {warmup_file_path}")

for dir in dirs:
    for algorithm in algorithms:
        root_dir = f"{dir}/{algorithm}"
        csv_files = glob.glob(os.path.join(root_dir, '*.csv'))
        for csv_file in csv_files:
            calculate_package_energy(csv_file)

print("All files have been processed.")
