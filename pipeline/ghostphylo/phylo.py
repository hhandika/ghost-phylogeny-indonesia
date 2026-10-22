"""Step 3: infer a maximum-likelihood tree with IQ-TREE.

ModelFinder chooses among Mk-type morphological models, and 1000 ultrafast
bootstrap replicates (refined with NNI, -bnni) give branch support. The binary
is taken from $IQTREE, else the first of iqtree3, iqtree2, iqtree on PATH.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess

from . import config as C

SEED = 20261020


def binary() -> str:
    for name in [os.environ.get("IQTREE"), "iqtree3", "iqtree2", "iqtree"]:
        if name and shutil.which(name):
            return shutil.which(name)  # type: ignore[return-value]
    raise SystemExit("IQ-TREE not found: install it or set $IQTREE")


def run(threads: str = "1") -> None:
    C.RESULTS.mkdir(parents=True, exist_ok=True)
    exe = binary()
    cmd = [
        exe,
        "-s", str(C.PROCESSED / f"{C.PREFIX}.nex"),
        "-st", "MORPH",
        "-m", "MFP",
        "-B", "1000",
        "-bnni",
        "-T", threads,
        "--seed", str(SEED),
        "-pre", str(C.RESULTS / C.PREFIX),
        "-redo",
        "-quiet",
    ]
    print("phylo:", " ".join([os.path.basename(exe)] + [os.path.relpath(c, C.ROOT) if os.path.isabs(c) else c for c in cmd[1:]]))
    subprocess.run(cmd, check=True)
    print(f"phylo: {summary()}")


def summary() -> dict:
    """Pull the headline numbers out of the IQ-TREE report."""
    report = (C.RESULTS / f"{C.PREFIX}.iqtree").read_text()

    def grab(pattern: str, cast=str):
        m = re.search(pattern, report, re.MULTILINE)
        return cast(m.group(1).strip()) if m else None

    version = grab(r"^IQ-TREE (?:multicore version )?(\d\S*)")
    return {
        "software": f"IQ-TREE {version}" if version else "IQ-TREE",
        "model": grab(r"^Best-fit model according to BIC:\s*(.+)$"),
        "logLikelihood": grab(r"^Log-likelihood of the tree:\s*(-?[\d.]+)", float),
        "bic": grab(r"^Bayesian information criterion \(BIC\) score:\s*([\d.]+)", float),
        "parsimonyInformative": grab(r"^Number of parsimony informative sites:\s*(\d+)", int),
        "constantSites": grab(r"^Number of constant sites:\s*(\d+)", int),
        "bootstrap": "1000 ultrafast bootstrap replicates (UFBoot2, -bnni)",
        "seed": SEED,
    }
