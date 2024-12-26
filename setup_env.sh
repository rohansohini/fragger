#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check if a Perl module is installed
is_perl_module_installed() {
    perl -M"$1" -e 1 2>/dev/null
}

# Function to install Perl modules if not already installed
install_perl_modules() {
    echo "Checking and installing missing Perl modules..."
    modules=("strict" "warnings" "HTTP::Tiny" "File::Spec" "JSON" "POSIX")
    for module in "${modules[@]}"; do
        if is_perl_module_installed "$module"; then
            echo "Perl module '$module' is already installed."
        else
            echo "Installing Perl module '$module'..."
            cpanm --notest "$module"
        fi
    done
}

# Function to install Mamba and set up the environment
install_mamba_env() {
    echo "Checking and setting up Mamba environment 'fragger'..."

    module purge all
    module load python-miniconda3/4.12.0
    module load mamba
    conda init bash
    source ~/.bashrc

    # Check if the 'fragger' environment already exists
    if mamba env list | grep -q '^fragger'; then
        echo "Mamba environment 'fragger' already exists."
    else
        echo "Creating Mamba environment 'fragger' with Python 3.10.1..."
        mamba create -n fragger python=3.10.1 -y
    fi
}

# Function to download and install BLAST databases
install_blast_databases() {
    echo "Installing BLAST databases..."
    
    module purge all
    module load blast
    
    # Directory to store BLAST databases
    blast_db_dir="./blast_db/"
    mkdir -p "$blast_db_dir"

    cd "$blast_db_dir"

    # List of BLAST database files to download
    blast_dbs=("human_genome")

    for db in "${blast_dbs[@]}"; do
        echo "Downloading BLAST database: $db..."
        update_blastdb.pl --decompress "$db"
    done
    
    cd ../

    echo "BLAST databases installed in $blast_db_dir"
}

# Main function
main() {
    echo "Starting setup..."
    
    # Install required Perl modules if missing
    install_perl_modules

    # Install Mamba and set up the environment
    install_mamba_env

    # Install BLAST databases
    install_blast_databases

    echo "Setup complete!"
}

# Execute the main function
main

