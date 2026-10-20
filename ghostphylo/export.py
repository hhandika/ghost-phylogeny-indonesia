"""Step 4: root the tree, ladderize it, and write one JSON file for the website."""

from __future__ import annotations

import json
import shutil
from datetime import date

from . import config as C
from . import encode, newick, phylo


def _to_json(n: newick.Node) -> dict:
    if n.is_tip:
        return {"id": n.name, "l": round(n.length, 6)}
    out: dict = {"l": round(n.length, 6), "c": [_to_json(c) for c in n.children]}
    if n.support is not None:
        out["s"] = round(n.support)
    return out


def _distances(tree: newick.Node) -> dict[str, dict[str, tuple[float, int]]]:
    """Patristic distance and node count between every pair of tips."""
    paths: dict[str, list[tuple[int, float]]] = {}
    for tip in tree.tips():
        path, n, depth = [], tip, 0.0
        while n is not None:
            path.append((id(n), depth))
            depth += n.length
            n = n.parent
        paths[tip.name] = path
    out: dict[str, dict[str, tuple[float, int]]] = {}
    for a, pa in paths.items():
        da = {node: (d, i) for i, (node, d) in enumerate(pa)}
        out[a] = {}
        for b, pb in paths.items():
            if a == b:
                continue
            for j, (node, d) in enumerate(pb):
                if node in da:
                    out[a][b] = (da[node][0] + d, da[node][1] + j)
                    break
    return out


def run(taxa: list[dict]) -> dict:
    tree = newick.parse((C.RESULTS / f"{C.PREFIX}.treefile").read_text())
    outgroups = {t["id"] for t in taxa if t["outgroup"]}
    tree, monophyletic = newick.reroot(tree, outgroups)
    newick.ladderize(tree)
    (C.RESULTS / f"{C.PREFIX}.rooted.tre").write_text(newick.write(tree) + "\n")

    matrix = encode.rows(taxa)
    by_row: dict[str, list[str]] = {}
    for k, v in matrix.items():
        by_row.setdefault(v, []).append(k)

    dist = _distances(tree)

    def hamming(a: str, b: str) -> int:
        return sum(x != y for x, y in zip(matrix[a], matrix[b]))

    ghosts = []
    for t in taxa:
        others = sorted(dist[t["id"]], key=lambda o: (round(dist[t["id"]][o][0], 6), dist[t["id"]][o][1], hamming(t["id"], o)))
        ghosts.append(
            {
                **t,
                "row": matrix[t["id"]],
                "twins": [o for o in by_row[matrix[t["id"]]] if o != t["id"]],
                "relatives": others[:5],
            }
        )

    supports = [n.support for n in tree.walk() if n.support is not None]
    data = {
        "meta": {
            "title": "Ghost phylogeny of Indonesia",
            "source": C.SOURCE_XLSX.name,
            "generated": date.today().isoformat(),
            "taxa": len(taxa),
            "outgroups": len(outgroups),
            "characters": len(encode.characters()),
            "uniqueRows": len(by_row),
            "outgroupMonophyletic": monophyletic,
            "nodes": len(supports),
            "strongNodes": sum(s >= 95 for s in supports),
            "weakNodes": sum(s < 50 for s in supports),
            "analysis": phylo.summary(),
        },
        "clades": C.CLADES,
        "regions": C.REGIONS,
        "bodyPlans": [{"id": k, "label": v} for k, v in C.BODY_PLANS],
        "characters": encode.characters(),
        "symbols": encode.SYMBOLS,
        "tree": _to_json(tree),
        "ghosts": ghosts,
    }
    C.WEB_DATA.parent.mkdir(parents=True, exist_ok=True)
    C.WEB_DATA.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n")

    # Downloadable analysis files for the Methods page.
    C.WEB_DOWNLOADS.mkdir(parents=True, exist_ok=True)
    for src in [
        C.PROCESSED / f"{C.PREFIX}.nex",
        C.PROCESSED / "ghosts.csv",
        C.PROCESSED / "characters.csv",
        C.RESULTS / f"{C.PREFIX}.rooted.tre",
        C.RESULTS / f"{C.PREFIX}.iqtree",
    ]:
        shutil.copyfile(src, C.WEB_DOWNLOADS / src.name)
    print(
        f"export: rooted on {'monophyletic' if monophyletic else 'largest'} outgroup clade, "
        f"{data['meta']['strongNodes']}/{len(supports)} nodes with UFBoot >= 95 -> {C.WEB_DATA.relative_to(C.ROOT)}"
    )
    return data
