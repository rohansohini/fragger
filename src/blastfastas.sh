#!/bin/bash

module purge all
module load blast || { echo "Failed to load blast module! Exiting."; exit 1; }

set -euo pipefail

# Paths
PARAMS_FILE="params.txt"
FASTA_DIR="fasta"  # Path to the fasta directory
RESULTS_DIR="results"  # Path to the results directory

# Determine BLAST_DB dynamically
BLAST_DB=$(ls ./blast_db/*.nto | sed 's/\.nto$//')

OUTPUT_FILE="$RESULTS_DIR/raw.csv"  # Combined BLAST output file

# Ensure required directories exist
mkdir -p "$FASTA_DIR" "$RESULTS_DIR"

# Check if params file is provided
if [ -z "$PARAMS_FILE" ]; then
    echo "Usage: $0 <params_file>"
    exit 1
fi

# Initialize arrays to store parameters
genes=()
wordsize=()
eval=()

# Read the params.txt file line by line
while IFS= read -r line; do
  # Skip comment lines and empty lines
  if [[ "$line" =~ ^# || -z "$line" ]]; then
    continue
  fi

  # Extract ncores if the line contains it
  if [[ "$line" =~ ^ncores= ]]; then
    ncores=$(echo "$line" | cut -d'=' -f2)
    continue
  fi

  # Extract organism if the line contains it
  if [[ "$line" =~ ^organism= ]]; then
    organism=$(echo "$line" | cut -d'=' -f2)
    organism="${organism//_/}" # remove the underscore from the organism name
    continue
  fi

  # Remove brackets and split the line into an array
  IFS=',' read -r -a params <<< "${line//[\[\]]}"

  # Append each parameter to its respective array
  genes+=("${params[0]}")
  wordsize+=("${params[1]}")
  eval+=("${params[2]}")
done < "$PARAMS_FILE"

# Set default ncores if not found in params.txt
ncores=${ncores:-12}

# Step 2: Run BLASTN on the generated FASTA files
echo "Running BLASTN with $ncores cores..."

# Initialize the output file (overwrite if it exists) and add column names
echo -e "seqid,sseqid,pident,length,mismatch,gapopen,sstart,send,qseq,sseq,evalue,bitscore" > "$OUTPUT_FILE"

# Loop through genes and process corresponding FASTA files
for i in "${!genes[@]}"; do
    gene="${genes[$i]}"
    FASTA_FILE="$FASTA_DIR/${gene}_${organism}.fasta"

    if [ ! -f "$FASTA_FILE" ]; then
        echo "FASTA file for gene $gene not found: $FASTA_FILE. Skipping..."
        continue
    fi

    echo "Processing $FASTA_FILE with wordsize ${wordsize[$i]} and eval ${eval[$i]}..."

    # Run BLASTN
    blastn -db "$BLAST_DB" -query "$FASTA_FILE" -word_size "${wordsize[$i]}" -evalue "${eval[$i]}" -num_threads "$ncores" -outfmt "10 qseqid sseqid pident length mismatch gapopen sstart send qseq sseq evalue bitscore" >> "$OUTPUT_FILE"
done

echo "All BLAST results have been written to $OUTPUT_FILE."

module purge all
