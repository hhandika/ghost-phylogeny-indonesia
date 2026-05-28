# ghost-phylogeny-indonesia

This is the actual ghost phylogeny. Literally, not conceptually...

## Overview

This repository contains a comprehensive dataset for inferring the evolutionary relationships among cryptids, spirits, and mythological entities across the Indonesian archipelago. The project utilizes phylogenetic methods to explore the morphological, ecological, and behavioral evolution of these cultural entities.

## Data

- **`data/indonesian_ghosts.nex`**: A morphological Nexus file containing 61 taxa (ghosts/entities) scored across various traits (Evolutionary Clade, Primary Morphology, Trophic Ecology, Behavioral Synapomorphies, Deterrents, and Phylogenetic Status). The matrix has been cleanly binarized into 90 presence/absence characters to ensure full compatibility with modern maximum-likelihood phylogenetic software like IQ-TREE.
- **`data/indonesian_ghosts.csv`**: A human-readable CSV dataset that maps directly to the Nexus matrix. It translates the binarized encodings back into their original, descriptive character states (e.g., "Volant Viscerophage", "Shapeshifts into animal") based on the `CHARSTATELABELS` definitions in the Nexus file. It contains the exact same 61 taxa and is perfect for quick reference, data exploration, or statistical analysis in R/Python.

## Character Traits

The dataset is built upon six primary groups of morphological, ecological, and behavioral characters:

1. **Evolutionary Clade**: Broader classification grouping entities based on overarching mythological or functional roles (e.g., *Volant Viscerophage*, *Vengeful Female*, *Pesugihan/Wealth Demon*).
2. **Primary Morphology**: The fundamental physical form of the entity (e.g., *Detached flying head*, *Spectral female*, *Bipedal primate/ape*, *Shrouded corpse*).
3. **Trophic Ecology & Diet**: What the entity consumes or requires for sustenance (e.g., *Blood/Fetuses*, *Flesh/Meat/Fauna*, *Life force/Soul*, *Non-consumptive*).
4. **Behavioral Synapomorphies**: Shared derived behavioral traits or specific habits unique to the entity's lore (e.g., *Echoing laugh/weeping*, *Kidnaps neglected children*, *Hopping locomotion/tied shroud*).
5. **Deterrents & Vulnerabilities**: Specific methods, objects, origins, or rituals used to repel, harm, or defeat the entity (e.g., *Vinegar/broken glass*, *Holy prayers/water*, *Untying the shroud knot*).
6. **Phylogenetic Status**: Indicates whether the entity is considered part of the main study group (*Ingroup*) or an outgroup used for rooting the phylogeny (*Outgroup*).

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

## Included Taxa

| Species / Entity | Distribution |
|---|---|
| Krasue | Thailand / Cambodia |
| Langsuyar | Malaysia |
| Manananggal | Philippines |
| Penanggalan | Malaysia |
| Bake | Asmat, Papua, Indonesia |
| Jero Gede Mecaling | Bali |
| Barong | Bali, Indonesia |
| Celuluk | Bali, Indonesia |
| Leak | Bali, Indonesia |
| Leyak | Bali, Indonesia |
| Rangda | Bali, Indonesia |
| Poppo | Bugis, Sulawesi |
| Antu Pala | Dayak, Kalimantan |
| Antu Raya | Dayak, Kalimantan |
| Ebu Gogo | Flores, Indonesia |
| Kelimutu Spirit | Flores, Indonesia |
| Jenglot | Indonesian Archipelago |
| Kuntilanak | Indonesian Archipelago |
| Toyol / Tuyul | Indonesian Archipelago |
| Nyi Roro Kidul | Java / Bali |
| Ahool | Java, Indonesia |
| Babi Ngepet | Java, Indonesia |
| Bajang | Java, Indonesia |
| Banaspati | Java, Indonesia |
| Batara Kala | Java, Indonesia |
| Buto Ijo | Java, Indonesia |
| Genderuwo | Java, Indonesia |
| Kepala Buntung | Java, Indonesia |
| Lampor | Java, Indonesia |
| Pocong | Java, Indonesia |
| Si Manis Jembatan Ancol | Java, Indonesia |
| Sundel Bolong | Java, Indonesia |
| Suster Ngesot | Java, Indonesia |
| Tuyul Buncit | Java, Indonesia |
| Wedon | Java, Indonesia |
| Wewe Gombel | Java, Indonesia |
| Antu Gerugugu | Kalimantan |
| Hantu Belian | Kalimantan |
| Tetek Arum | Kalimantan |
| Kuyang | Kalimantan, Indonesia |
| Senggiq | Lombok, Indonesia |
| Leak | Lombok, NTT |
| Bakkara | Makassar, Sulawesi |
| Ina Ama | Maluku, Indonesia |
| Momoa | Maluku, Indonesia |
| Nitu | Maluku, Indonesia |
| Suanggi | Maluku, Indonesia |
| Naga | NTT, Indonesia |
| Homang | Papua, Indonesia |
| Kaiamunu | Papua, Indonesia |
| Kapre | Papua, Indonesia |
| Ndope | Sentani, Papua, Indonesia |
| Orang Bati | Seram, Indonesia |
| Tandi Barane | Sulawesi |
| Begu Ganjang | Sumatra, Indonesia |
| Cindaku | Sumatra, Indonesia |
| Orang Pendek | Sumatra, Indonesia |
| Batitong | Toraja, Sulawesi |
| Bombo | Toraja, Sulawesi |
| Tosalili | Toraja, Sulawesi |
| Palasik | West Sumatra, Indonesia |
