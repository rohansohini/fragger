#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Paths
PARAMS_FILE="params.txt"

# Check if params file is provided
if [ -z "$PARAMS_FILE" ]; then
    echo "Usage: $0 <params_file>"
    exit 1
fi

# Read the params.txt file line by line
while IFS= read -r line; do
  # Skip comment lines and empty lines
  if [[ "$line" =~ ^# || -z "$line" ]]; then
    continue
  fi

  # Extract organism if the line contains it
  if [[ "$line" =~ ^organism= ]]; then
    organism=$(echo "$line" | cut -d'=' -f2)
    continue
  fi
done < "$PARAMS_FILE"

# Set default ncores if not found in params.txt
ncores=${ncores:-12}

# Function to install BLAST databases
install_blast_databases() {
    echo "Installing BLAST databases..."

    module purge all
    module load blast

    # Directory to store BLAST databases
    blast_db_dir="./blast_db/"
    mkdir -p "$blast_db_dir"

    # If the blast_db directory exists, remove the old files before downloading
    rm -rf "$blast_db_dir"/*

    cd "$blast_db_dir"

    # Determine the correct BLAST database
    case "$organism" in
        "homo_sapiens") blast_db="human_genome" ;;
        "mus_musculus") blast_db="mouse_genome" ;;
        *) blast_db="ref_euk_rep_genomes" ;;  # Default for other eukaryotes
    esac

    echo "Downloading BLAST database: $blast_db..."
    update_blastdb.pl --decompress "$blast_db"
    
    cd ../

    echo "BLAST database installed: $blast_db"
}

# Function to download and extract GTF annotation files from Ensembl
install_ensembl_annotations() {
    echo "Installing Ensembl genome annotations..."

    # Directory to store annotation files
    annotations_dir="./annotation/"
    mkdir -p "$annotations_dir"

    cd "$annotations_dir"

    rm -rf ./*

    # Convert organism to lowercase to match Ensembl's format
    ensembl_species=$(echo "$organism" | tr '[:upper:]' '[:lower:]')

    # Set Ensembl release version
    ensembl_release="113"

    # Define specific file naming conventions for each organism
    case "$organism" in
        "homo_sapiens") gtf_file="Homo_sapiens.GRCh38.${ensembl_release}.gtf.gz" ;;
        "mus_musculus") gtf_file="Mus_musculus.GRCm39.${ensembl_release}.gtf.gz" ;;
        "saccharomyces_cerevisiae") gtf_file="Saccharomyces_cerevisiae.R64-1-1.${ensembl_release}.gtf.gz" ;;
        "danio_rerio") gtf_file="Danio_rerio.GRCz11.${ensembl_release}.gtf.gz" ;;
        "caenorhabditis_elegans") gtf_file="Caenorhabditis_elegans.WBcel235.${ensembl_release}.gtf.gz" ;;
        *)
            echo "Unsupported organism: $organism"
            return 1
            ;;
    esac

    # Construct the URL for downloading GTF files from Ensembl
    base_url="https://ftp.ensembl.org/pub/release-${ensembl_release}/gtf"
    gtf_url="$base_url/$ensembl_species/$gtf_file"

    echo "Downloading GTF annotation for: $gtf_file (Release $ensembl_release)..."
    
    # Download and extract the GTF file
    wget "$gtf_url" -O "$gtf_file"

    if [ -f "$gtf_file" ]; then
        gunzip -f "$gtf_file"
        echo "Annotation file downloaded and extracted: $gtf_file"
    else
        echo "Failed to download GTF annotation for $ensembl_species."
    fi

    cd ../
}

# Main function
main() {
    echo "Starting setup..."

    # Check if the organism is one of the ones that should skip BLAST db download
    case "$organism" in
        "danio_rerio" | "saccharomyces_cerevisiae" | "caenorhabditis_elegans")
            echo "Skipping BLAST database download for $organism."
            ;;
        *)
            # Install BLAST databases if not skipping
            install_blast_databases
            ;;
    esac

    # Install GTF file
    install_ensembl_annotations

    echo "Setup complete!"
}

# Execute the main function
main