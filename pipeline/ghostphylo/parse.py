"""Step 1: read the source table and write a clean, typed table of taxa."""

from __future__ import annotations

import csv
import json

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
    with open(C.SOURCE_CSV, newline="", encoding="utf-8-sig") as f:
        rows = list(csv.DictReader(f))
    trait_ids = [t["id"] for t in C.TRAITS]
    missing = [t for t in trait_ids if t not in rows[0]]
    if missing:
        raise SystemExit(f"Source is missing trait columns: {missing}")

    taxa = []
    for r in rows:
        if not r["Taxon"]:
            continue
        tid = r["Taxon"].strip()
        origin = _text(r["Description_Origin"])
        deterrent = _text(r["Deterrents_Vulnerabilities"])
        # Original rows repeat one value in both columns; keep it where it belongs.
        if origin and origin == deterrent:
            if C.ORIGIN_LIKE.search(deterrent):
                deterrent = None
            else:
                origin = None
        traits = {}
        for t in trait_ids:
            v = r[t].strip()
            traits[t] = None if v in ("?", "") else int(v)
        coding = r["Coding_Source"]
        morphology = C.FUSED.get(r["Primary_Morphology"], r["Primary_Morphology"])
        diet = C.FUSED.get(r["Trophic_Ecology_Diet"], r["Trophic_Ecology_Diet"])
        taxa.append(
            {
                "id": tid,
                "name": C.display_name(tid, r["Common_Name"]),
                "region": C.americanize(r["Island_Region"]),
                "regionGroup": C.region_group(r["Island_Region"]),
                "culture": _text(r["Ethnic_Cultural_Origin"]),
                "clade": C.clean_clade(r["Evolutionary_Clade"]),
                "morphology": C.americanize(morphology),
                "bodyPlan": C.body_plan(morphology),
                "diet": C.americanize(diet),
                "dietClass": C.diet_class(diet),
                "danger": int(r["Danger_Level_1_5"]),
                "origin": origin,
                "appearance": _text(r["Appearance"]),
                "behavior": _text(r["Behavior"]),
                "deterrents": deterrent,
                "popCulture": _text(r["Pop_Culture_Notes"]),
                "outgroup": r["Phylogenetic_Status"].strip() == "Outgroup",
                "inSourceTree": r["In_Phylogeny_Tree"].startswith("Yes"),
                "coding": "source" if coding == "Original" else ("new" if coding.startswith("New") else "filled"),
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
