import pandas as pd
import numpy as np
import os

RAPL_COLUMNS = [
    "Algorithm",
    "Package Energy (J)",
    "Core Energy (J)",
    "Uncore Energy (J)",
    "DRAM Energy (J)",
    "Elapsed Time (ms)",
]


def read_csv_safely(path):
    try:
        if not os.path.exists(path):
            raise Exception("file does not exist")
        return pd.read_csv(path, header=0)
    except Exception as ex:
        raise RuntimeError(f"Failed to read {path}: {str(ex)}")


def calculate_energy(df, power_unit: int):
    """Calculate energy metrics from raw data."""
    multiplier = 0.5 ** ((power_unit >> 8) & 0x1F)
    pkg = (df.iloc[:, 7] - df.iloc[:, 6]) * multiplier
    core = (df.iloc[:, 3] - df.iloc[:, 2]) * multiplier
    uncore = (df.iloc[:, 5] - df.iloc[:, 4]) * multiplier
    dram = (df.iloc[:, 9] - df.iloc[:, 8]) * multiplier
    time = df.iloc[:, 1] - df.iloc[:, 0]
    return pkg, core, uncore, dram, time
