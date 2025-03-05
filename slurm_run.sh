#!/bin/bash

#SBATCH --account=XXXXX ## Required: your allocation/account name, i.e. eXXXX, pXXXX or bXXXX
#SBATCH --partition=short ## Required: (buyin, short, normal, long, gengpu, genhimem, etc)
#SBATCH --time=04:00:00 ## Required: How long will the job need to run
#SBATCH --nodes=1 ## how many computers/nodes do you need
#SBATCH --ntasks-per-node=28 ## how many cpus or processors (should match ncores in params.txt)
#SBATCH --mem=100G ## how much memory per node
#SBATCH --job-name=fragger ## job name

# Change to the submission directory
cd "$SLURM_SUBMIT_DIR"

# Clear  modules
module purge all

# Measure execution time
START_TIME=$(date +%s)

# Function to print error message and exit
die() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Function to print update messages
update() {
    echo "[INFO] $1"
}

update "Starting the pipeline..."

# 1. Build exclusion list to exclude genes in protein network
update "Building fasta files and exclusion list..."
python3 src/build.py || die "Failed to build fasta and exclusion lists. Check src/build.py for errors."

# 2. BLAST the fasta files
update "Running BLAST on fasta files..."
bash src/blastfastas.sh || die "Failed to run BLAST. Check src/blastfastas.sh for errors."

# 5. Processing the BLAST output
update "Processing and filtereing BLAST output files..."
python3 src/process.py || die "Failed to process and filter BLAST files. Check src/process.py for errors."

update "Pipeline completed successfully."

END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))

echo "fragger took $ELAPSED_TIME seconds to complete."

# Unload modules
module purge all
