# fragger: BLAST-based Tool to Study Transcriptional Adaptation

## Introduction
**fragger** is a custom tool designed to study the role of sequence similarity in transcriptional adaptation. Transcriptional adaptation is an mRNA-mediated genetic compensation mechanism where certain mutations rendering a gene non-functional can lead to the upregulation of a *similar* compensatory gene. fragger helps explore the importance of nucleotide similarity between mutated genes and their compensators.

fragger performs the following key steps:
1. **Fragmentation:** Chop a gene's sequence (representing a mutated gene) into fragments.
2. **BLAST Analysis:** Use BLAST to find genes with similar sequences to each fragment.
3. **Filtering:** Remove BLAST results that belong to the same protein network.

---

## Notes
- **fragger** is designed for human genes and is optimized to run on Northwestern's Quest High Performance Computing (HPC) system. Some scripts may need adjustment for other systems, such as modifications to module names.

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
   [GENE1,fmethod1,fval1,wordsize1,eval1,excgene1,ppisize1]
   [GENE2,fmethod2,fval2,wordsize2,eval2,excgene2,ppisize2]
   [GENE3,fmethod3,fval3,wordsize3,eval3,excgene3,ppisize3]
   ...
   
   ncores=c
   ```
   - **`GENE:`** List the genes to be fragmented and BLASTed (comma-separated).
   - **`fmethod:`** Set the method for fragmentation. This can either be *nfrag* or *fragsize*. Choose *nfrag* if you want to divide into *n* fragments and choose *fragsize* if you want to divide into fragments of *v* length.
   - **`fval:`** Depending on your fmethod, set to either *n* or *v*
   - **`wordsize:`** Set the word_size for BLAST query ([Learn more about e-values](https://www.metagenomics.wiki/tools/blast/default-word-size).
   - **`eval:`** Set the e-value threshold ([Learn more about e-values](https://www.ncbi.nlm.nih.gov/books/NBK279682/)).
   - **`excgene:`** Set to either *true* or *false*. Setting to *true* will filter out BLAST matches to the **`GENE:`** from the final output.
   - **`ppisize:`** Limit the number of genes identified in the queried gene's protein network from [STRING-db](https://string-db.org/). Default: `10`.
   - **`ncores:`** Specify the number of cores, *c*, available for the scripts.

4. **Run the environment setup script:**
   ```bash
   bash setup_env.sh
   ```

---

## Running fragger

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
   For instructions on running fragger using an HPC (specifically Northwestern's Quest) see below.

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

## Using fragger in Northwestern's HPC Quest

1. **Set the working directory:**
   ```bash
   cd your_path/fragger/
   ```
   
2. **Run the following line of commands in your home node each time you enter the HPC:**
   ```bash
   module purge all
   module load perl/5.36.0-gcc-10.4.0 gcc/10.4.0-gcc-4.8.5

   cpan
   o conf makepl_arg "INSTALL_BASE=~/perl5"
   o conf mbuildpl_arg "--install_base ~/perl5"
   o conf commit
   exit

   export PERL5LIB=~/perl5/lib/perl5:$PERL5LIB
   export PATH=~/perl5/bin:$PATH

   cpan Canary::Stability
   cpan JSON
   ```
   
3. **Edit the account, available number of cores, and memory in  **`slurm_run.sh`****
   Change the following lines below to match your job request. Example values are provided below:
   ```bash
   #SBATCH --account=p12345
   #SBATCH --ntasks-per-node=28
   #SBATCH --mem=50G
   ```
   Make sure --ntasks-per-node matches what was set in `params.txt` for **`ncores:`**.

4. **Submit the job**
   ```bash
   sbatch slurm_run.sh
   ```   
---

## Support
For additional support or bug reports, please open an issue in this repository or contact rohansohini2026@u.northwestern.edu.
