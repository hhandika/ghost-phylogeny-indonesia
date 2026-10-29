"""Step 6: a dichotomous key to the ghosts, built from the coded characters.

Each couplet splits the remaining ghosts on one character: one state against
the rest. The coded traits come first, then body plan, diet, and region as
fallbacks. A ghost scored variable or unknown for the chosen character keys
out under both leads, as in a printed flora. Ghosts that no character can
separate end together at one lead.
"""

from __future__ import annotations

from . import config as C

# Fallback characters, tried only when no coded trait splits the group.
_FALLBACK_COST = {"trait": 0.0, "body_plan": 0.1, "diet": 0.15, "region": 0.3}


def _characters(taxa: list[dict]) -> list[dict]:
    """Each character as {id, label, kind, states, value(taxon) -> state index or None}."""
    chars = []
    for t in C.TRAITS:
        # State 2 means variable for every trait except sex, where it is a state.
        ambiguous = set() if t["id"] == "sex" else {2}
        chars.append(
            {
                "id": t["id"],
                "label": t["label"],
                "kind": "trait",
                "states": t["states"],
                "value": lambda g, k=t["id"], amb=ambiguous: None if g["traits"][k] in amb else g["traits"][k],
            }
        )
    plans = [k for k, _ in C.BODY_PLANS]
    chars.append({"id": "body_plan", "label": "Body plan", "kind": "body_plan", "states": [v for _, v in C.BODY_PLANS], "value": lambda g: plans.index(g["bodyPlan"])})
    chars.append({"id": "diet", "label": "Diet", "kind": "diet", "states": C.DIETS, "value": lambda g: None if g["dietClass"] is None else C.DIETS.index(g["dietClass"])})
    chars.append({"id": "region", "label": "Region", "kind": "region", "states": C.REGIONS, "value": lambda g: C.REGIONS.index(g["regionGroup"])})
    return chars


def _best_split(group: list[dict], chars: list[dict]):
    """The character and state that halve the group best, with few ghosts on both sides."""
    best = None
    n = len(group)
    for c in chars:
        values = [c["value"](g) for g in group]
        observed = sorted({v for v in values if v is not None})
        if len(observed) < 2:
            continue
        ambiguous = values.count(None)
        # A binary trait has one split; a multistate character one per state.
        candidates = [1] if c["kind"] == "trait" and c["id"] != "sex" else observed
        for s in candidates:
            yes = [g for g, v in zip(group, values) if v == s or v is None]
            no = [g for g, v in zip(group, values) if v != s]
            if len(yes) == n or len(no) == n:
                continue
            score = min(len(yes), len(no)) / n - ambiguous / n - _FALLBACK_COST[c["kind"]]
            if best is None or score > best[0]:
                rest = [v for v in observed if v != s]
                best = (score, c, s, rest, yes, no)
    return best


def build(taxa: list[dict]) -> dict:
    """Couplets numbered depth first; each lead goes to a couplet or ends in ghosts."""
    chars = _characters(taxa)
    by_id = {c["id"]: c for c in chars}
    couplets: list[dict] = []
    order = sorted(taxa, key=lambda g: g["name"].lower())

    def lead(c: dict, states: list[int], negate: bool) -> dict:
        return {"char": c["id"], "states": [c["states"][s] for s in states], "not": negate}

    def walk(group: list[dict], parent: int | None) -> int:
        split = _best_split(group, chars)
        assert split is not None
        _, c, s, rest, yes, no = split
        number = len(couplets) + 1
        couplet = {"n": number, "from": parent, "leads": []}
        couplets.append(couplet)
        # With one other state, name it; with several, say "not" the chosen one.
        sides = [(yes, lead(c, [s], False)), (no, lead(c, rest, False) if len(rest) == 1 else lead(c, [s], True))]
        for members, item in sides:
            couplet["leads"].append(item)
            if len(members) == 1 or _best_split(members, chars) is None:
                item["ghosts"] = [g["id"] for g in members]
            else:
                item["to"] = walk(members, number)
        return number

    walk(order, None)

    keyed: dict[str, list[int]] = {}
    for cp in couplets:
        for item in cp["leads"]:
            for g in item.get("ghosts", []):
                keyed.setdefault(g, []).append(cp["n"])
    missing = [g["id"] for g in taxa if g["id"] not in keyed]
    assert not missing, f"ghosts lost from the key: {missing}"
    return {
        "characters": [{"id": c["id"], "label": c["label"]} for c in chars if any(it["char"] == c["id"] for cp in couplets for it in cp["leads"])],
        "couplets": couplets,
        "index": {g: sorted(set(ns)) for g, ns in sorted(keyed.items())},
        "used": sorted({it["char"] for cp in couplets for it in cp["leads"]}, key=list(by_id).index),
    }


def text(key: dict, taxa: list[dict]) -> str:
    """The key as plain text, for data/processed/key.txt."""
    names = {g["id"]: g["name"] for g in taxa}
    labels = {c["id"]: c["label"] for c in key["characters"]}
    out = [f"Dichotomous key to {len(taxa)} ghosts. Generated by ghostphylo.key; do not edit by hand.", ""]
    for cp in key["couplets"]:
        num = f"{cp['n']}({cp['from']})" if cp["from"] else str(cp["n"])
        for i, item in enumerate(cp["leads"]):
            states = " or ".join(item["states"])
            desc = f"{labels[item['char']]}: {'not ' if item['not'] else ''}{states}"
            end = f"{cp['n']}{'ab'[i]}"
            target = str(item["to"]) if "to" in item else ", ".join(names[g] for g in item["ghosts"])
            out.append(f"{(num if i == 0 else '').ljust(9)}{end.ljust(6)}{desc} {'.' * max(2, 70 - len(desc))} {target}")
        out.append("")
    return "\n".join(out)


def run(taxa: list[dict]) -> dict:
    key = build(taxa)
    (C.PROCESSED / "key.txt").write_text(text(key, taxa))
    shared = sum(1 for cp in key["couplets"] for it in cp["leads"] if len(it.get("ghosts", [])) > 1)
    twice = sum(1 for ns in key["index"].values() if len(ns) > 1)
    print(f"key: {len(key['couplets'])} couplets, {twice} ghosts keyed out more than once, {shared} leads end in ghosts no character separates -> key.txt")
    return key
