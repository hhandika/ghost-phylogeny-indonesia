"""Run the pipeline: `uv run ghostphylo [parse|encode|tree|export|svg|all]`."""

from __future__ import annotations

import argparse

from . import encode, export, parse, phylo, svgs


def main() -> None:
    ap = argparse.ArgumentParser(prog="ghostphylo", description=__doc__)
    ap.add_argument("step", nargs="?", default="all", choices=["parse", "encode", "tree", "export", "svg", "all"])
    ap.add_argument("--threads", default="1", help="IQ-TREE -T value; 1 (default) keeps seeded runs reproducible")
    args = ap.parse_args()

    taxa = parse.run()
    if args.step in ("encode", "tree", "all"):
        encode.run(taxa)
    if args.step in ("tree", "all"):
        phylo.run(args.threads)
    if args.step in ("export", "all"):
        export.run(taxa)
    if args.step in ("svg", "all"):
        svgs.run(taxa)


if __name__ == "__main__":
    main()
