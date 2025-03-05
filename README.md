# fragger: BLAST-based Tool to Study Transcriptional Adaptation

## Introduction
**fragger** is a custom tool designed to study the role of sequence similarity in transcriptional adaptation. Transcriptional adaptation is an mRNA-mediated genetic compensation mechanism where certain mutations rendering a gene non-functional can lead to the upregulation of a *similar* compensatory gene. fragger helps explore the importance of nucleotide similarity between mutated genes and their compensators.

fragger performs the following key steps:
1. **BLAST Analysis:** Use BLAST to find genes with similar sequences to *fragments* of the queried gene(s).
2. **Annotation Retrieval:** Use Ensembl's annotation files to provide additional context for each BLAST hit.
3. **Filtering:** Remove BLAST results that belong to the same protein network.

---

## Notes
- **fragger** is designed primarily for human and mouse genes and is optimized to run on Northwestern's Quest High Performance Computing (HPC) system. Some scripts may need adjustment for other systems, such as modifications to module names, scripts, and computing resources.

---

## Installation

1. **Clone fragger from GitHub:**
   - **HTTPS:**
     ```bash
     git clone https://github.com/rohansohini/fragger.git
     ```
   - **SSH:**
     ```bash
     git clone git@github.com:rohansohini/fragger.git
     ```

2. **Set the working directory:**
   Ensure the working directory is set to the "fragger" folder:
   ```bash
   cd fragger
   ```

3. **Edit parameters:**
   Open `params.txt`, add vectors of genes with their parameters, and set the number of cores available.
   ```bash
   nano params.txt
   ```
   ```bash
   [GENE1,wordsize1,eval1,excgene1,ppisize1]
   [GENE2,wordsize2,eval2,excgene2,ppisize2]
   [GENE3,wordsize3,eval3,excgene3,ppisize3]
   ...
   
   ncores=c
   ...

   organism=h
   ```
   - **`GENE:`** List the genes to be fragmented and BLASTed (comma-separated).
   - **`wordsize:`** Set the word_size for BLAST query ([Learn more about e-values](https://www.metagenomics.wiki/tools/blast/default-word-size).
   - **`eval:`** Set the e-value threshold ([Learn more about e-values](https://www.ncbi.nlm.nih.gov/books/NBK279682/)).
   - **`excgene:`** Set to either *true* or *false*. Setting to *true* will filter out BLAST matches to the **`GENE:`** from the final output.
   - **`ppisize:`** Limit the number of genes identified in the queried gene's protein network from [STRING-db](https://string-db.org/). Default: `10`.
   - **`ncores:`** Specify the number of cores, *c*, available for the scripts. This must match `slurm_run.sh`.
   - **`organism:`** Specify the organism you are working with in the format `genus_species`.

4. **Run the environment setup script:**
   ```bash
   bash setup_env.sh
   ```
   - **Notes:** If using an organism other than `homo_sapiens` or `mus_musculus`, the Ensembl annotation file will be downloaded into **`annotation`**, but the BLAST database files will ***not*** be downloaded into the **`blast_db`** folder. You must instead download your genome's fasta file and use the provided annotation file to make your own reference (to store in **`blast_db`**) using a tool like CellRanger. An example is provided below for *danio_rerio*.     
   
   ```bash
   # example for builiding reference for danio_rerio
   ~/packages/cellranger-9.0.0/cellranger mkref \
      --genome=GRCz11 \
      --fasta=Danio_rerio.GRCz11.dna.primary_assembly.fa \
      --genes=Danio_rerio.GRCz11.113.gtf \
      --ref-version=1.0.0 \
      --memgb=100
   ```
5. **Edit SLURM paramters in `slurm_run.sh`**
   Open `slurm_run.sh` using `nano slurm_run.sh` and edit the account number and computing requirements to fit your need. Ensure the number of cores matches `ncores` in `params.txt`.
   ```bash
   #SBATCH --account=XXXXX ## Required: your allocation/account name, i.e. eXXXX, pXXXX or bXXXX
   #SBATCH --partition=short ## Required: (buyin, short, normal, long, gengpu, genhimem, etc)
   #SBATCH --time=04:00:00 ## Required: How long will the job need to run (default: 4 hours)
   #SBATCH --nodes=1 ## how many computers/nodes do you need (fragger is designed for 1 node)
   #SBATCH --ntasks-per-node=28 ## how many cpus or processors (should match ncores in params.txt)
   #SBATCH --mem=100G ## how much memory per node
   #SBATCH --job-name=fragger ## job name
   ```
---

## Running fragger

1. **Set the working directory:**
   ```bash
   cd your_path/fragger/
   ```

2. **Run fragger:**
   After setting the parameters in `params.txt` and `slurm_run.sh`, execute the pipeline:
   ```bash
   sbatch slurm_run.sh
   ```
   For instructions on running fragger without SLURM, see below.

3. **Access the results:**
   The filtered output will be stored in:
   ```
   your_path/fragger/results/filtered.csv
   ```

---

## Using fragger in Northwestern's HPC Quest

1. **Set the working directory:**
   ```bash
   cd your_path/fragger/
   ```
   
2. **Start a screen session:**
   Use GNU Screen to allow the process to run in the background:
   ```bash
   screen
   ```
   Learn more about [GNU Screen here](https://www.gnu.org/software/screen/manual/screen.html).

3. **Run fragger:**
   After setting the parameters in `params.txt`, execute the pipeline:
   ```bash
   bash run.sh
   ```
   Note: **It is *not* recommended to use fragger this way**.

4. **Exit the screen:**
   Detach from the screen session without stopping the pipeline:
   ```
   <Ctrl> + a + d
   ```
5. **Re-enter the screen session:**
   To check the pipeline's progress, re-attach to the screen:
   ```bash
   screen -r
   ```

6. **Finish the process:**
   Once the pipeline completes, type `exit` within the screen session to close it.

7. **Access the results:**
   The filtered output will be stored in:
   ```
   your_path/fragger/results/filtered.csv
   ```
---

## Support
For additional support, customization, or bug reports, please open an issue in this repository or contact rohansohini2026@u.northwestern.edu.
