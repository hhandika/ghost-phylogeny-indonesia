"""Step 1: read the workbook and write a clean, typed table of taxa."""

from __future__ import annotations

import csv
import json

import openpyxl

from . import config as C


def _text(value) -> str | None:
    if value is None:
        return None
    s = " ".join(str(value).split())
    s = C.americanize(C.FUSED.get(s, s))
    if not s or s == "Unknown" or C.BOILERPLATE.search(s):
        return None
    return s


def parse() -> list[dict]:
    wb = openpyxl.load_workbook(C.SOURCE_XLSX, read_only=True, data_only=True)
    rows = list(wb["Ghosts"].iter_rows(values_only=True))
    header = [str(h) for h in rows[0]]
    trait_ids = [t["id"] for t in C.TRAITS]
    missing = [t for t in trait_ids if t not in header]
    if missing:
        raise SystemExit(f"Workbook is missing trait columns: {missing}")

    taxa = []
    for raw in rows[1:]:
        if not raw or not raw[0]:
            continue
        r = dict(zip(header, raw))
        tid = str(r["Taxon_ID"]).strip()
        origin = _text(r["Origin_Story"])
        deterrent = _text(r["Deterrents_Vulnerabilities"])
        # Original rows carry the origin in the deterrent column.
        if deterrent and C.ORIGIN_LIKE.search(deterrent):
            origin = origin or deterrent
            deterrent = None
        traits = {}
        for t in trait_ids:
            v = r[t]
            traits[t] = None if v in (None, "?", "") else int(v)
        inferred = str(r["Inferred_Coding"] or "")
        taxa.append(
            {
                "id": tid,
                "name": C.display_name(tid, str(r["Name"])),
                "region": C.americanize(str(r["Island_Region"])),
                "regionGroup": C.region_group(str(r["Island_Region"])),
                "culture": _text(r["Ethnic_Cultural_Origin"]),
                "clade": C.clean_clade(str(r["Clade"])),
                "morphology": C.americanize(str(r["Morphology"])),
                "bodyPlan": C.body_plan(str(r["Morphology"])),
                "diet": C.americanize(str(r["Diet"])),
                "dietClass": C.diet_class(str(r["Diet"])),
                "danger": int(r["Danger_Level_1_5"]),
                "origin": origin,
                "appearance": _text(r["Appearance"]),
                "behavior": _text(r["Behavior"]),
                "deterrents": deterrent,
                "popCulture": _text(r["Pop_Culture_Notes"]),
                "outgroup": str(r["Status_Ingroup_Outgroup"]).strip() == "Outgroup",
                "inSourceTree": str(r["Sampled_In_Phylogeny"]).startswith("Yes"),
                "coding": "source" if inferred.startswith("No") else ("new" if "new v3" in inferred else "filled"),
                "traits": traits,
            }
        )

    ids = [t["id"] for t in taxa]
    dupes = {i for i in ids if ids.count(i) > 1}
    if dupes:
        raise SystemExit(f"Duplicate taxon IDs: {sorted(dupes)}")
    names = [t["name"] for t in taxa]
    dupes = {n for n in names if names.count(n) > 1}
    if dupes:
        raise SystemExit(f"Duplicate display names, add NAME_OVERRIDES: {sorted(dupes)}")
    return taxa


def run() -> list[dict]:
    taxa = parse()
    C.PROCESSED.mkdir(parents=True, exist_ok=True)
    (C.PROCESSED / "ghosts.json").write_text(json.dumps(taxa, indent=1, ensure_ascii=False) + "\n")
    flat_keys = [k for k in taxa[0] if k != "traits"]
    with open(C.PROCESSED / "ghosts.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(flat_keys + [t["id"] for t in C.TRAITS])
        for t in taxa:
            w.writerow([t[k] for k in flat_keys] + ["?" if t["traits"][c["id"]] is None else t["traits"][c["id"]] for c in C.TRAITS])
    print(f"parse: {len(taxa)} taxa ({sum(t['outgroup'] for t in taxa)} outgroups) -> {C.PROCESSED.relative_to(C.ROOT)}")
    return taxa
