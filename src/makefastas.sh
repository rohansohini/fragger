#!/bin/bash

module purge all
set -euo pipefail

# Paths
GENE_LIST="src/genes.txt"  # Path to the file containing gene symbols
FASTA_DIR="fasta"  # Path to the fasta directory

# Clear all previous fasta files
rm -f "$FASTA_DIR"/*.fasta

# Import parameters from params.txt
PARAMS_FILE="./params.txt"
frag_size=$(grep -oP '^fragsize=\K.*' "$PARAMS_FILE")

# Ensure required directories exist
if [ ! -d "$FASTA_DIR" ]; then
    echo "FASTA directory does not exist. Creating it..."
    mkdir -p "$FASTA_DIR" || { echo "Failed to create FASTA directory! Exiting."; exit 1; }
fi

# Check if gene list file is provided
if [ -z "$GENE_LIST" ]; then
    echo "Usage: $0 <gene_list_file>"
    exit 1
fi

# Step 1: Create FASTA files using fragment.pl
echo "Generating FASTA files..."
while IFS= read -r gene_symbol; do
    echo "Processing gene: $gene_symbol"
    perl "src/fragments.pl" "$gene_symbol" "$frag_size" "${FASTA_DIR}"
done < "$GENE_LIST"
