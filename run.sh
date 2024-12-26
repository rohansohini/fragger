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

# 1. Build list of genes
update "Building list of genes..."
bash src/make_genes.sh || die "Failed to build list of genes. Check src/make_genes.sh for errors."

# 2. Build exclusion list to exclude genes in protein network
update "Building exclusion list..."
perl src/exclusion.pl || die "Failed to build exclusion list. Check src/exclusion.pl for errors."

# 3. Make the fasta files for each gene
update "Creating fasta files for each gene..."
bash src/makefastas.sh || die "Failed to create fasta files. Check src/makefastas.sh for errors."

# 4. BLAST the fasta files
update "Running BLAST on fasta files..."
bash src/blastfastas.sh || die "Failed to run BLAST. Check src/blastfastas.sh for errors."

# 5. Filter the fasta files
update "Filtering fasta files..."
python3 src/filter.py || die "Failed to filter fasta files. Check src/filter.py for errors."

update "Pipeline completed successfully."
