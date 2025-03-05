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
