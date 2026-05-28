# ghost-phylogeny-indonesia
This is the actual ghost phylogeny. Literally, not conceptually...

## Overview
This repository contains a comprehensive dataset for inferring the evolutionary relationships among cryptids, spirits, and mythological entities across the Indonesian archipelago. The project utilizes phylogenetic methods to explore the morphological, ecological, and behavioral evolution of these cultural entities.

## Data
- **`data/indonesian_ghosts.nex`**: A morphological Nexus file containing 61 taxa (ghosts/entities) scored across various traits (Evolutionary Clade, Primary Morphology, Trophic Ecology, Behavioral Synapomorphies, Deterrents, and Phylogenetic Status). The matrix has been cleanly binarized into 90 presence/absence characters to ensure full compatibility with modern maximum-likelihood phylogenetic software like IQ-TREE.
- **`data/indonesian_ghosts.csv`**: A human-readable CSV dataset that maps directly to the Nexus matrix. It translates the binarized encodings back into their original, descriptive character states (e.g., "Volant Viscerophage", "Shapeshifts into animal") based on the `CHARSTATELABELS` definitions in the Nexus file. It contains the exact same 61 taxa and is perfect for quick reference, data exploration, or statistical analysis in R/Python.

## Usage
To reconstruct the phylogeny, we provide a shell script configured to run IQ-TREE with standard best practices (ModelFinder Plus and 1000 ultrafast bootstraps).

```bash
# Ensure the script is executable
chmod +x scripts/run_iqtree.sh

# Run the IQ-TREE analysis
./scripts/run_iqtree.sh
```

Results will automatically be saved to the `results/iqtree_output/` directory.

## Requirements
- **IQ-TREE 2**: Must be installed and available in your `PATH` as `iqtree2`.
