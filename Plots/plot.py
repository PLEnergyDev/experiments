import pandas as pd
import seaborn as sns

import matplotlib
import matplotlib.pyplot as plt

sns.set(style="whitegrid")

rows = ['Elapsed Time (ms)', 'Package Energy (µJ)', 'DRAM Energy (µJ)', 'Temperature (C°)']
# you need to this this dict manually
experiments = {
    # 'Plot Category': {
        # 'Title of plot': '/path/to/csv/file.csv',
        # 'Side by side title of plot': '/path/to/csv/file.csv',
    # },
    # 'Another Plot Category': {
        # 'Title of plot': '/path/to/csv/file.csv',
        # 'Side by side title of plot': '/path/to/csv/file.csv',
    # }
}

fig, axs = plt.subplots(nrows=len(rows), ncols=len(experiments) * 2, figsize=(len(experiments) * 15, len(rows) * 5), sharey='row')
fig.subplots_adjust(hspace=0.4, wspace=0.4)

# Load and plot data for each experiment and condition
for exp_i, (experiment_name, conditions) in enumerate(experiments.items()):
    for condition_name, file_path in conditions.items():
        df = pd.read_csv(file_path, delimiter=',')  # Load the dataframe
        
        for row_i, row in enumerate(rows):
            # Prepare data for plotting
            combined_data = df.assign(Condition=condition_name)
            
            # Determine the subplot index
            violin_ax_index = row_i, exp_i
            box_ax_index = row_i, exp_i + len(experiments)
            
            # Plot violin plot
            sns.violinplot(x='Condition', y=row, data=combined_data, ax=axs[violin_ax_index])
            
            # Plot box plot
            sns.boxplot(x='Condition', y=row, data=combined_data, ax=axs[box_ax_index])
            
            # Set titles
            axs[violin_ax_index].set_title(row)
            axs[box_ax_index].set_title(row)
            axs[violin_ax_index].set_xlabel(experiment_name)
            axs[box_ax_index].set_xlabel(experiment_name)

plt.tight_layout()
plt.savefig('foo.png')
