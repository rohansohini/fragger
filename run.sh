#!/bin/bash

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

# Ensure the correct environment is activated
update "Activating conda environment 'fragger'..."
module purge all || die "Failed to purge modules. Check your environment."
eval "$(conda shell.bash hook)"
conda activate fragger || die "Failed to activate conda environment 'fragger'. Ensure it is installed."
update "Environment activated."

# 1. Build exclusion list to exclude genes in protein network
update "Building exclusion list..."
bash src/makeexclusions.sh || die "Failed to build exclusion lists. Check src/exclusion.pl for errors."

# 2. Make the fasta files for each gene
update "Creating fasta files for each gene..."
bash src/makefastas.sh || die "Failed to create fasta files. Check src/makefastas.sh for errors."

# 3. BLAST the fasta files
update "Running BLAST on fasta files..."
bash src/blastfastas.sh || die "Failed to run BLAST. Check src/blastfastas.sh for errors."

# 5. Filter the fasta files
update "Filtering fasta files..."
python3 src/filter.py || die "Failed to filter fasta files. Check src/filter.py for errors."

update "Pipeline completed successfully."
