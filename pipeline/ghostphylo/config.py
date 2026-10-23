"""Paths, character definitions, and the cleaning rules for the source table."""

from __future__ import annotations

import re
from pathlib import Path

# The package lives in pipeline/ghostphylo; data, results, and the apps sit at
# the repository root.
ROOT = Path(__file__).resolve().parents[2]
SOURCE_CSV = ROOT / "data" / "indonesian-ghosts.csv"
PROCESSED = ROOT / "data" / "processed"
RESULTS = ROOT / "results" / "iqtree"
WEB_DATA = ROOT / "web" / "src" / "data" / "phylogeny.json"
WEB_SVG = ROOT / "web" / "public" / "ghosts"
WEB_DOWNLOADS = ROOT / "web" / "public" / "data"
PREFIX = "ghosts"

# ---- The 18 coded traits ----------------------------------------------------
# States follow the dataset README: 0 absent, 1 present, 2 not applicable or
# variable; for sex 1 is female and 2 male / unspecified.
TRAITS: list[dict] = [
    {"id": "domain_human_like", "label": "Human-like", "states": ["Non-human, animal, or object", "Humanoid, witch, or human spirit", "Variable"]},
    {"id": "sex", "label": "Sex", "states": ["Male", "Female", "Male, unspecified, or variable"]},
    {"id": "origin_death_birth", "label": "Death or birth origin", "states": ["Not death or birth related", "Death, childbirth, or infant origin", "Variable"]},
    {"id": "corporeality", "label": "Incorporeal", "states": ["Embodied creature or witch", "Ghost, spirit, or undead", "Variable"]},
    {"id": "locomotion_flight", "label": "Flight", "states": ["Grounded", "Flies or floats", "Variable"]},
    {"id": "burial_association", "label": "Burial", "states": ["None or weak", "Grave, shroud, or cemetery", "Variable"]},
    {"id": "child_association", "label": "Children", "states": ["None", "Child spirit, child theft, or infant targeting", "Variable"]},
    {"id": "predation_blood_organs", "label": "Blood and organs", "states": ["None", "Targets blood, flesh, or organs", "Variable"]},
    {"id": "theft_mischief", "label": "Theft and mischief", "states": ["None", "Theft, pranks, or mischief central", "Variable"]},
    {"id": "body_hair_or_fur", "label": "Hair or fur", "states": ["None", "Hairy, furry, or ape-like", "Variable"]},
    {"id": "animal_transformation", "label": "Animal form", "states": ["None", "Animal form or shapeshifting central", "Variable"]},
    {"id": "head_detachment", "label": "Detached head", "states": ["None", "Detached or flying head", "Variable"]},
    {"id": "fire_luminosity", "label": "Fire or light", "states": ["None", "Fireball, flaming, or luminous", "Variable"]},
    {"id": "aquatic_association", "label": "Water", "states": ["None", "Sea, river, or water", "Variable"]},
    {"id": "forest_association", "label": "Forest", "states": ["None", "Forest, jungle, or mountain", "Variable"]},
    {"id": "domestic_settlement", "label": "Settlement", "states": ["Wild or liminal", "Village, house, hospital, or road", "Variable"]},
    {"id": "apotropaic_magic", "label": "Black magic", "states": ["No strong sorcery motif", "Black magic or witchcraft central", "Variable"]},
    {"id": "southeast_asia_wide", "label": "Widespread", "states": ["Localized", "Widespread across Southeast Asia", "Variable"]},
]

# ---- Clades -----------------------------------------------------------------
# The source spells some clades with and without slashes. Order is the fixed
# categorical order of the site palette (validated for adjacent CVD contrast).
CLADES = [
    "Vengeful Female",
    "Nature / Ancestral Spirit",
    "Volant Viscerophage",
    "Pesugihan / Wealth Demon",
    "Therianthrope / Shapeshifter",
    "Undead / Revenant",
    "Elemental / Demonic",
    "Hominid Cryptid",
    "Volant Cryptid",
]
_CLADE_KEY = {re.sub(r"[^a-z]", "", c.lower()): c for c in CLADES}


def clean_clade(raw: str) -> str:
    return _CLADE_KEY[re.sub(r"[^a-z]", "", raw.lower())]


# ---- Regions ----------------------------------------------------------------
REGIONS = [
    "Sumatra",
    "Java",
    "Bali",
    "Nusa Tenggara",
    "Kalimantan",
    "Sulawesi",
    "Maluku",
    "Papua",
    "Widespread",
    "Outgroup",
]


def region_group(raw: str) -> str:
    if "outgroup" in raw.lower():
        return "Outgroup"
    for key, group in [
        ("Widespread", "Widespread"),
        ("Archipelago-wide", "Widespread"),
        ("Sumatra", "Sumatra"),
        ("Java", "Java"),
        ("Bali", "Bali"),
        ("Flores", "Nusa Tenggara"),
        ("Lombok", "Nusa Tenggara"),
        ("Nusa Tenggara", "Nusa Tenggara"),
        ("Kalimantan", "Kalimantan"),
        ("Sulawesi", "Sulawesi"),
        ("Maluku", "Maluku"),
        ("Papua", "Papua"),
    ]:
        if key.lower() in raw.lower():
            return group
    raise ValueError(f"Unmapped region: {raw}")


# ---- Diet (coded as one multistate character) ------------------------------
DIETS = ["Blood", "Flesh", "Life force or offerings", "Non-consumptive", "Omnivore"]


def diet_class(raw: str) -> str | None:
    d = raw.lower().replace("nonconsumptive", "non-consumptive")
    if d.startswith("unknown"):
        return None
    if d.startswith("blood"):
        return "Blood"
    if d.startswith("flesh"):
        return "Flesh"
    if d.startswith("life force") or d.startswith("spiritual"):
        return "Life force or offerings"
    if d.startswith("non-consumptive"):
        return "Non-consumptive"
    if d.startswith("omnivore"):
        return "Omnivore"
    raise ValueError(f"Unmapped diet: {raw}")


# ---- Body plan (coded as one multistate character, and drives the SVGs) ----
BODY_PLANS = [
    ("spectral_female", "Spectral female"),
    ("flying_head", "Detached flying head"),
    ("upper_torso", "Detached upper torso"),
    ("primate", "Hairy biped"),
    ("shrouded_corpse", "Shrouded corpse"),
    ("fireball", "Fireball"),
    ("giant", "Giant or ogre"),
    ("winged", "Winged hominid"),
    ("tiger", "Tiger-human"),
    ("elongated", "Elongated humanoid"),
    ("procession", "Haunted object or procession"),
    ("serpent", "Serpent or naga"),
    ("masked", "Masked deity"),
    ("witch", "Human witch"),
    ("animal", "Animal or animal hybrid"),
    ("humanoid_spirit", "Humanoid spirit"),
    ("aquatic", "Aquatic spirit"),
    ("child", "Child-like familiar"),
    ("hungry_ghost", "Hungry ghost"),
]

_BODY_RULES = [
    ("hungry ghost", "hungry_ghost"),
    ("child-like", "child"),
    ("spirit child", "child"),
    ("aquatic", "aquatic"),
    ("water ghost", "aquatic"),
    ("water spirit", "aquatic"),
    ("water demon", "aquatic"),
    ("sea ghost", "aquatic"),
    ("river guardian", "aquatic"),
    ("sea queen", "spectral_female"),
    ("human witch", "witch"),
    ("transformed witch", "witch"),
    ("flying head", "flying_head"),
    ("upper torso", "upper_torso"),
    ("shrouded corpse", "shrouded_corpse"),
    ("reanimated corpse", "shrouded_corpse"),
    ("headless priest", "shrouded_corpse"),
    ("fireball", "fireball"),
    ("winged", "winged"),
    ("tiger", "tiger"),
    ("elongated", "elongated"),
    ("extremely tall", "elongated"),
    ("palm-tall", "elongated"),
    ("coffin", "procession"),
    ("object haunting", "procession"),
    ("spectral train", "procession"),
    ("spectral ambulance", "procession"),
    ("serpent", "serpent"),
    ("naga", "serpent"),
    ("snake", "serpent"),
    ("masked", "masked"),
    ("spectral female", "spectral_female"),
    ("spectral woman", "spectral_female"),
    ("spectral old woman", "spectral_female"),
    ("spectral schoolgirl", "spectral_female"),
    ("lady ghost", "spectral_female"),
    ("nurse ghost", "spectral_female"),
    ("female spirit", "spectral_female"),
    ("primate", "primate"),
    ("hairy humanoid", "primate"),
    ("giant hominid", "primate"),
    ("noted for teeth", "primate"),
    ("gigantic", "giant"),
    ("humanoid demon", "giant"),
    ("crocodile", "animal"),
    ("familiar", "animal"),
    ("horse", "animal"),
    ("animal", "animal"),
    ("dog-like", "animal"),
    ("viscera-sucker", "animal"),
    ("viscera feeder", "animal"),
    ("beast-like", "animal"),
]


def body_plan(morphology: str) -> str:
    m = morphology.lower()
    for key, plan in _BODY_RULES:
        if key in m:
            return plan
    return "humanoid_spirit"


# ---- Text clean-up ----------------------------------------------------------
# The source lost its slashes at some point, which fused words
# ("laughweeping"). These restore the original separators.
FUSED = {
    "Bipedal primateape": "Bipedal primate / ape-like",
    "Elongatedstretching humanoid": "Elongated / stretching humanoid",
    "Floating fireballflame entity": "Floating fireball / flame entity",
    "Flying coffinspectral procession": "Flying coffin / spectral procession",
    "Gigantic humanoidogre": "Gigantic humanoid / ogre",
    "Maskedcostumed deity form": "Masked / costumed deity form",
    "Serpentnaga hybrid": "Serpent / naga hybrid",
    "Tigerhuman hybrid": "Tiger–human hybrid",
    "Nonconsumptive": "Non-consumptive",
    "Spiritual energyofferings": "Spiritual energy / offerings",
    "Ajian magicnocturnal hunting": "Ajian magic; nocturnal hunting",
    "Burns victimsspontaneous combustion": "Burns victims; spontaneous combustion",
    "Cavedwellingrudimentary language": "Cave-dwelling; rudimentary language",
    "Conceals backpatriarchal revenge": "Conceals her back; patriarchal revenge",
    "Cosmic guardianbattles evil entities": "Cosmic guardian; battles evil entities",
    "Crawling on floorshospital association": "Crawls on floors; hospital association",
    "Echoing laughweeping": "Echoing laugh or weeping",
    "Grows taller when looked atstrangles": "Grows taller when looked at; strangles",
    "Headless locomotionterrifies passersby": "Headless locomotion; terrifies passers-by",
    "Hereditaryattacks unborn": "Hereditary; attacks the unborn",
    "Hopping locomotiontied shroud": "Hopping locomotion; tied shroud",
    "Inhabits sacred stonestreessprings": "Inhabits sacred stones, trees, and springs",
    "Loud knockingbrings disease": "Loud knocking; brings disease",
    "Massive wingspanvocalisation": "Massive wingspan; vocalisation",
    "Punitive cursegluttony": "Punitive curse for gluttony",
    "Ritual selftransformation via black magic": "Ritual self-transformation via black magic",
    "Seduces fishermencontrols sea wealth": "Seduces fishermen; controls sea wealth",
    "Seducescorrupts mendemands blood sacrifice": "Seduces and corrupts men; demands blood sacrifice",
    "Shapeshifts into animalpossesses victims": "Shapeshifts into animals; possesses victims",
    "Transforms in ancestral landsguardian spirit": "Transforms in ancestral lands; guardian spirit",
    "Garlic amuletsreversed clothing": "Garlic amulets; reversed clothing",
    "Glass beadsneedleseggs": "Glass beads, needles, and eggs",
    "Holy prayerswater": "Holy prayers and water",
    "Loud noisesbanging pots": "Loud noises; banging pots",
    "Saltashgarlic on lower torso": "Salt, ash, or garlic on the lower torso",
    "Specific ritual offeringsBanyan wood": "Specific ritual offerings; banyan wood",
    "Specific ritual offerings / Banyan wood": "Specific ritual offerings; banyan wood",
    "Vinegarbroken glass": "Vinegar and broken glass",
    "Violent murderbetrayal origin": "Violent murder or betrayal origin",
    "None Biological entity": "None; a biological entity",
}

# The site is written in American English; the source mixes in British forms.
AMERICAN = {
    "favour": "favor",
    "travellers": "travelers",
    "odour": "odor",
    "vocalisation": "vocalization",
    "popularised": "popularized",
    "behaviour": "behavior",
    "colour": "color",
}
_AMERICAN_RE = re.compile(r"\b(" + "|".join(AMERICAN) + r")\b", re.IGNORECASE)


def americanize(s: str) -> str:
    def swap(m: re.Match) -> str:
        word = AMERICAN[m.group(0).lower()]
        return word.capitalize() if m.group(0)[0].isupper() else word

    return _AMERICAN_RE.sub(swap, s)


TRANSLATIONS = ROOT / "data" / "translations"

# In the original 61 rows the origin and deterrent columns hold the same value,
# which is one or the other.
ORIGIN_LIKE = re.compile(r"origin$|^Parental remorse$|^Breaking ancestral taboo$")

BOILERPLATE = re.compile(r"^Folklore-synthesis summary|\(see Morphology and Behavior fields\)$|Coded features are in the trait matrix|See Morphology and trait matrix|^Recurring figure in Indonesian horror|^Comparative expansion entry")

# Trailing place words in the source names ("Ndope Sentani").
PLACE_WORDS = {
    "java", "bali", "sumatra", "west", "kalimantan", "sulawesi", "maluku", "papua",
    "ntt", "flores", "lombok", "malaysia", "philippines", "thailand", "cambodia", "ap",
    "dayak", "toraja", "bugis", "makassar", "seram", "asmat", "sentani",
}
NAME_OVERRIDES = {
    "toyol_tuyul_indonesian_archipelago": "Toyol / Tuyul",
    "leak_bali_indonesia": "Leak (Bali)",
    "leak_lombok_ntt": "Leak (Lombok)",
    "naga_ntt_indonesia": "Naga (Nusa Tenggara)",
    "kelimutu_spirit_flores_indonesia": "Kelimutu spirit",
    "waruga_spirit_sulawesi_indonesia": "Waruga spirit",
}


def display_name(taxon_id: str, raw: str) -> str:
    if taxon_id in NAME_OVERRIDES:
        return NAME_OVERRIDES[taxon_id]
    words = raw.split()
    while len(words) > 1 and words[-1].lower() in PLACE_WORDS:
        words.pop()
    return " ".join(words)
