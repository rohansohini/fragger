#!/bin/bash

#SBATCH --account=<account> ## Required: your allocation/account name, i.e. eXXXX, pXXXX or bXXXX
#SBATCH --partition=short ## Required: (buyin, short, normal, long, gengpu, genhimem, etc)
#SBATCH --time=04:00:00 ## Required: How long will the job need to run
#SBATCH --nodes=1 ## how many computers/nodes do you need
#SBATCH --ntasks-per-node=28 ## how many cpus or processors (should match ncores in params.txt)
#SBATCH --mem=50G ## how much memory per node
#SBATCH --job-name=fragger ## job name

# Change to the submission directory
cd "$SLURM_SUBMIT_DIR"

# Load necessary modules
module purge all
module load perl/5.36.0-gcc-10.4.0 gcc/10.4.0-gcc-4.8.5

# Run the script
bash run.sh

# Unload modules
module purge all
