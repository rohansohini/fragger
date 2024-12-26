# fragger: BLAST-based Tool to Study Transcriptional Adaptation

## Introduction
**fragger** is a custom tool designed to study the role of sequence similarity in transcriptional adaptation. Transcriptional adaptation is an mRNA-mediated genetic compensation mechanism where certain mutations rendering a gene non-functional can lead to the upregulation of a *similar* compensatory gene. fragger helps explore the importance of nucleotide similarity between mutated genes and their compensators.

fragger performs the following key steps:
1. **Fragmentation:** Chop a gene's sequence (representing a mutated gene) into *n* fragments.
2. **BLAST Analysis:** Use BLAST to find genes with similar sequences to each fragment.
3. **Filtering:** Remove BLAST results that belong to the same protein network.

---

## Notes
- **fragger** is designed for human genes and is optimized to run on Northwestern's Quest High Performance Computing (HPC) system. Some scripts may need adjustment for other systems, such as modifications to module names.

---

## Installation

1. **Clone fragger from GitHub:**
   ```bash
   git clone https://github.com/rohansohini/fragger.git
   ```

2. **Set the working directory:**
   Ensure the working directory is set to the "fragger" folder:
   ```bash
   cd fragger
   ```

3. **Edit parameters:**
   Open `params.txt` and adjust the parameters as needed:
   ```bash
   nano params.txt
   ```
   - **`genes:`** List the genes to be fragmented and BLASTed (comma-separated).
   - **`eval:`** Set the e-value threshold ([Learn more about e-values](https://www.ncbi.nlm.nih.gov/books/NBK279682/)).
   - **`limit:`** Limit the number of genes identified in the queried gene's protein network from [STRING-db](https://string-db.org/). Default: `10`.
   - **`ncores:`** Specify the number of cores available for the scripts.

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
For additional support or bug reports, please open an issue in this repository or contact rohansohini2026@u.northwestern.edu.
