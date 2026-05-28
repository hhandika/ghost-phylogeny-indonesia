#!/bin/bash

# Navigate to the directory containing the script to resolve relative paths
cd "$(dirname "$0")"

# Define paths relative to the scripts directory
DATA_FILE="../data/indonesian_ghosts.nex"
OUTPUT_DIR="../results/iqtree_output"
PREFIX="${OUTPUT_DIR}/indonesian_ghosts"

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# Run IQ-TREE
# -s   : input alignment
# -pre : output prefix
# -B   : 1000 ultrafast bootstrap replicates
# -m   : ModelFinder Plus (default)
# -nt  : automatically determine the best number of threads
# -bnni: bootstrapping with nearest neighbor interchange heuristic
echo "Starting IQ-TREE analysis on ${DATA_FILE}..."
iqtree2 -s "${DATA_FILE}" -pre "${PREFIX}" -B 1000 -m MFP -T AUTO -bnni

echo "IQ-TREE analysis completed. Results are located in ${OUTPUT_DIR}"
