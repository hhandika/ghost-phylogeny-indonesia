"""Step 5: draw one SVG specimen plate per ghost.

Each plate is a night-sky disc ringed in the clade colour. The figure comes
from the body plan (with a few named variants), and the coded traits add the
scenery: a banyan for forest, nisan gravestones and frangipani for burial, a
joglo roof with a lit window for settlements, waves for water, kepeng coins
for theft, a smoking incense burner for black magic, and so on. A seed taken
from the taxon ID varies pose, stars, and moon, so no two plates match.

Plates are deterministic: the same source always yields the same files.
A hand-drawn file in assets/ghosts/<taxon_id>.svg replaces the generated one.
"""

from __future__ import annotations

import hashlib
import math
import random
import shutil

from . import config as C

# ---- Palette (fixed: plates are always night scenes) ------------------------
INK = "#15111f"
HAIR = "#0b0910"
KAFAN = "#f1e9d8"  # burial shroud
KAFAN_SHADE = "#d4c6aa"
DARAH = "#a3172d"  # blood
PRADA = "#d9ab3c"  # gold leaf
GLOW = "#ffd27a"
EYE_RED = "#ff4a4a"
# Clade ring colours: the dark-mode steps of the site palette.
CLADE_RING = ["#e04a62", "#16a08c", "#bf8a1f", "#7d74e6", "#d8703c", "#3f8fd0", "#cc5aa6", "#6aa23a", "#9d7cf0"]

# Visual tweaks for named taxa whose coded body plan undersells the legend.
VISUAL = {
    "toyol_tuyul_indonesian_archipelago": {"plan": "child"},
    "tuyul_buncit_java_indonesia": {"plan": "child", "belly": True},
    "babi_ngepet_java_indonesia": {"plan": "animal", "animal": "boar"},
    "ahool_java_indonesia": {"plan": "winged", "bat": True},
    "bajang_java_indonesia": {"plan": "animal", "animal": "cat"},
    "jenglot_indonesian_archipelago": {"scale": 0.72, "fangs": True},
    "orang_pendek_sumatra_indonesia": {"scale": 0.82},
    "ebu_gogo_flores_indonesia": {"scale": 0.78},
    "celuluk_bali_indonesia": {"fangs": True},
    "rangda_bali_indonesia": {"plan": "masked", "mask": "rangda"},
    "barong_bali_indonesia": {"plan": "masked", "mask": "barong"},
    "calon_arang_java_bali": {"mask": "rangda"},
    "nyi_roro_kidul_java_bali": {"crown": True, "dress": "#1f7a62"},
    "nyai_blorong_java_indonesia": {"crown": True, "dress": "#2f6e4a"},
    "dewi_lanjar_java_indonesia": {"crown": True, "dress": "#2b6f8e"},
    "putri_tangguk_sumatra_indonesia": {"crown": True},
    "kuntilanak_merah_java_indonesia": {"dress": "#9e1d2c"},
    "pocong_merah_java_indonesia": {"shroud": "#a8343c"},
    "pocong_gundul_java_indonesia": {"bald": True},
    "kepala_buntung_java_indonesia": {"headless": True},
    "pastur_kepala_buntung_java": {"headless": True, "shroud": "#2a2433"},
    "antu_pala_dayak_kalimantan": {"plan": "flying_head"},
    "churel_south_asia": {"backwards": True},
    "buto_ijo_java_indonesia": {"skin": "#3f7d3a"},
    "kolor_ijo_java_indonesia": {"skin": "#3f7d3a", "scale": 0.86},
    "mariaban_kalimantan_indonesia": {"fur": "#8c3f24"},
    "hantu_buaya_putih_indonesia": {"animal": "crocodile"},
    "tikbalang_philippines": {"animal": "horse"},
    "aul_kalimantan_indonesia": {"animal": "dog", "headless": True},
    "grandong_java_indonesia": {"animal": "dog"},
    "aswang_philippines": {"animal": "dog"},
    "siluman_indonesian_archipelago": {"animal": "cat"},
    "kereta_hantu_manggarai_java": {"object": "train"},
    "hantu_ambulans_bandung_java": {"object": "ambulance"},
    "jin_qarin_indonesian_archipelago": {"spirit": "double"},
    "hantu_jeruk_purut_java": {"spirit": "dog", "headless": True},
    "orang_bunian_sumatra_kalimantan": {"spirit": "bunian"},
    "mambang_malay_archipelago": {"spirit": "sun"},
    "waruga_spirit_sulawesi_indonesia": {"spirit": "waruga"},
    "hantu_rimba_indonesian_archipelago": {"spirit": "leaves"},
    "hantu_penunggu_indonesia": {"spirit": "shrine"},
    "tonya_sulawesi_indonesia": {"spirit": "shrine"},
    "dedemit_java_indonesia": {"spirit": "shrine"},
    "hantu_pusako_sumatra_indonesia": {"spirit": "keris"},
    "kapre_papua_indonesia": {"cigar": True},
}


# ---- Small drawing helpers --------------------------------------------------

def p(d: str, fill: str = "none", stroke: str = INK, sw: float = 2.2, extra: str = "") -> str:
    s = f' stroke="{stroke}" stroke-width="{sw}"' if stroke != "none" else ""
    return f'<path d="{d}" fill="{fill}"{s}{extra}/>'


def circle(cx, cy, r, fill, stroke="none", sw=0.0, extra=""):
    s = f' stroke="{stroke}" stroke-width="{sw}"' if stroke != "none" else ""
    return f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{fill}"{s}{extra}/>'


def ellipse(cx, cy, rx, ry, fill, stroke="none", sw=0.0, extra=""):
    s = f' stroke="{stroke}" stroke-width="{sw}"' if stroke != "none" else ""
    return f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="{fill}"{s}{extra}/>'


def limb(d: str, color: str, w: float = 5.0) -> str:
    """A stroked limb with an ink outline."""
    return p(d, stroke=INK, sw=w + 2.4, extra=' stroke-linecap="round"') + p(d, stroke=color, sw=w, extra=' stroke-linecap="round"')


def eyes(cx, cy, gap, r, danger, glow=False):
    out = []
    for x in (cx - gap, cx + gap):
        if danger >= 4 or glow:
            out.append(circle(x, cy, r * 1.9, EYE_RED, extra=' opacity="0.35"'))
            out.append(circle(x, cy, r, EYE_RED))
            out.append(circle(x, cy, r * 0.4, "#ffe2d6"))
        else:
            out.append(circle(x, cy, r, INK))
            out.append(circle(x + r * 0.3, cy - r * 0.3, r * 0.3, "#ffffff"))
    return "".join(out)


def blob(cx, cy, rx, ry, n, amp, rng, start=0.0):
    """A shaggy outline: alternating radius around an ellipse."""
    pts = []
    for i in range(n * 2):
        a = start + math.pi * 2 * i / (n * 2)
        k = 1 + (amp if i % 2 == 0 else -amp * 0.4) * (0.7 + 0.6 * rng.random())
        pts.append((cx + math.cos(a) * rx * k, cy + math.sin(a) * ry * k))
    d = f"M{pts[0][0]:.1f} {pts[0][1]:.1f} " + " ".join(f"L{x:.1f} {y:.1f}" for x, y in pts[1:]) + " Z"
    return d


def hem(x0, x1, y, n, depth):
    """A tattered hem from x1 back to x0 (path continuation)."""
    step = (x1 - x0) / n
    return " ".join(f"Q{x1 - step * (i + 0.5):.1f} {y - depth:.1f} {x1 - step * (i + 1):.1f} {y:.1f}" for i in range(n))


# ---- Figures ----------------------------------------------------------------

def long_hair_head(cx, cy, danger, crown=False, face=KAFAN):
    out = [
        ellipse(cx, cy, 11, 13, face, INK, 2),
        p(f"M{cx-12} {cy-10} C{cx-10} {cy-18} {cx+10} {cy-18} {cx+12} {cy-10} C{cx+14} {cy+4} {cx+16} {cy+24} {cx+18} {cy+46} "
          f"C{cx+13} {cy+34} {cx+10} {cy+14} {cx+8} {cy-2} C{cx+4} {cy-6} {cx-4} {cy-6} {cx-8} {cy-2} "
          f"C{cx-10} {cy+14} {cx-13} {cy+34} {cx-18} {cy+46} C{cx-16} {cy+24} {cx-14} {cy+4} {cx-12} {cy-10} Z", HAIR, INK, 1.5),
        eyes(cx, cy + 2, 4, 1.7, danger),
        ellipse(cx, cy + 8, 1.5, 2.3, INK),
    ]
    if crown:
        out.append(p(f"M{cx-10} {cy-12} l2 -10 l5 6 l3 -10 l3 10 l5 -6 l2 10 Z", PRADA, INK, 1.4))
        out.append(circle(cx, cy - 15, 1.6, DARAH))
    return "".join(out)


def spectral_female(t, v, rng):
    dress = v.get("dress", KAFAN)
    shade = "#000000" if dress != KAFAN else KAFAN_SHADE
    gown = f"M69 62 C62 82 54 106 46 128 L114 128 C106 106 98 82 91 62 Z"
    # The hem is drawn as its own tattered edge over the gown.
    tatters = "M46 128 " + " ".join(f"Q{46 + 11.33 * i + 5.7:.1f} {136 if i % 2 else 133} {46 + 11.33 * (i + 1):.1f} 128" for i in range(6))
    out = [
        p("M66 40 C58 62 56 92 60 112 L100 112 C104 92 102 62 94 40 Z", HAIR, INK, 1.5),
        p(gown, dress, INK, 2.2),
        p(tatters + " L114 124 L46 124 Z", dress, "none"),
        p(tatters, "none", INK, 2),
        p("M74 80 C72 98 68 112 66 124 M86 80 C88 98 92 112 94 124", "none", shade, 1.4, ' opacity="0.35"'),
        limb("M70 66 C64 78 60 90 57 102", KAFAN, 4.4),
        limb("M90 66 C96 78 100 90 103 102", KAFAN, 4.4),
        p("M57 102 l-3 7 M57 102 l0 8 M57 102 l3 7 M103 102 l-3 7 M103 102 l0 8 M103 102 l3 7", "none", INK, 1.3),
        long_hair_head(80, 46, t["danger"], v.get("crown", False)),
    ]
    if v.get("backwards"):
        out.append(p("M66 130 c-2 4 4 6 10 4 l-2 -4 Z M94 130 c2 4 -4 6 -10 4 l2 -4 Z", KAFAN, INK, 1.6))
    if t["traits"].get("child_association") == 1 and t["traits"].get("origin_death_birth") == 1:
        # Jasmine sprigs in the hair: the scent that announces her.
        out.append("".join(circle(68 + i * 3, 36 - (i % 2) * 2, 1.6, "#ffffff", INK, 0.6) for i in range(3)))
    return "".join(out)


def flying_head(t, v, rng):
    out = [
        p("M66 46 C52 34 40 24 26 22 C40 30 46 36 50 44 C40 40 30 40 22 46 C34 46 44 50 54 56 Z", HAIR, INK, 1.4),
        p("M94 46 C108 34 120 24 134 22 C120 30 114 36 110 44 C120 40 130 40 138 46 C126 46 116 50 106 56 Z", HAIR, INK, 1.4),
        p("M78 72 C76 82 80 88 78 96", "none", INK, 6, ' stroke-linecap="round"'),
        p("M78 72 C76 82 80 88 78 96", "none", "#d88a8a", 3.6, ' stroke-linecap="round"'),
        p("M78 86 C66 86 62 100 66 106 C72 108 76 98 78 92 Z M80 86 C92 86 96 100 92 106 C86 108 82 98 80 92 Z", "#b5485a", INK, 1.6),
        p("M79 96 C72 98 72 108 79 112 C86 108 86 98 79 96 Z", "#8f1028", INK, 1.6),
        p("M79 112 C70 116 92 120 82 126 C72 130 90 134 80 140", "none", "#c45a6a", 4.5, ' stroke-linecap="round"'),
        p("M66 106 C62 116 66 124 62 132", "none", "#c45a6a", 3, ' stroke-linecap="round"'),
        circle(62, 137, 1.8, DARAH), circle(80, 146, 2, DARAH),
        ellipse(80, 54, 15, 17, KAFAN, INK, 2.2),
        p("M66 46 C66 32 94 32 94 46 C90 40 70 40 66 46 Z", HAIR, INK, 1.4),
        eyes(80, 54, 5.5, 2.2, t["danger"]),
        p("M73 64 Q80 70 87 64 Q80 74 73 64 Z", DARAH, INK, 1.2),
        p("M75 65 l1.5 3 l1.5 -3 M83 65 l1.5 3 l1.5 -3", "#ffffff", "none"),
    ]
    return "".join(out)


def bat_wing(side: int, color="#4a3a5c", rib="#8a7aa0", y=60):
    s = side
    x0 = 80 + s * 12
    d = (f"M{x0} {y} C{80 + s*30} {y-26} {80 + s*56} {y-30} {80 + s*72} {y-14} "
         f"C{80 + s*62} {y-4} {80 + s*62} {y+4} {80 + s*64} {y+14} C{80 + s*52} {y+6} {80 + s*46} {y+10} {80 + s*44} {y+22} "
         f"C{80 + s*34} {y+12} {80 + s*26} {y+16} {x0} {y+26} Z")
    ribs = f"M{x0} {y+4} L{80 + s*72} {y-14} M{x0} {y+8} L{80 + s*64} {y+14} M{x0} {y+14} L{80 + s*44} {y+22}"
    return p(d, color, INK, 2) + p(ribs, "none", rib, 1.2)


def upper_torso(t, v, rng):
    out = [
        bat_wing(-1), bat_wing(1),
        p("M66 66 C64 80 68 92 72 100 L76 96 L80 102 L84 96 L88 100 C92 92 96 80 94 66 C86 60 74 60 66 66 Z", KAFAN, INK, 2.2),
        p("M76 100 C70 112 78 118 72 128 M82 100 C88 110 82 120 88 132", "none", "#c45a6a", 4, ' stroke-linecap="round"'),
        circle(72, 133, 1.8, DARAH), circle(88, 137, 1.8, DARAH),
        long_hair_head(80, 48, t["danger"]),
    ]
    return "".join(out)


def primate(t, v, rng):
    fur = v.get("fur", "#5a4232")
    face = "#8f6c54"
    out = [
        p(blob(80, 96, 28, 32, 22, 0.12, rng), fur, INK, 2),
        p(blob(56, 98, 8, 24, 10, 0.18, rng, 0.3), fur, INK, 1.8),
        p(blob(104, 98, 8, 24, 10, 0.18, rng, 0.6), fur, INK, 1.8),
        ellipse(52, 122, 6, 5, face, INK, 1.6), ellipse(108, 122, 6, 5, face, INK, 1.6),
        ellipse(70, 128, 9, 6, fur, INK, 1.8), ellipse(90, 128, 9, 6, fur, INK, 1.8),
        p(blob(80, 54, 17, 16, 14, 0.14, rng), fur, INK, 2),
        ellipse(80, 58, 11, 10, face, INK, 1.6),
        p("M70 51 Q80 46 90 51", "none", INK, 2),
        eyes(80, 55, 4.5, 2, t["danger"]),
        ellipse(80, 62, 3, 1.6, INK),
        p("M74 66 Q80 70 86 66", "none", INK, 1.6),
    ]
    if v.get("fangs") or t["traits"].get("predation_blood_organs") == 1:
        out.append(p("M76 66 l1.4 4 l1.4 -3.6 M82 66.4 l1.4 3.6 l1.4 -4", "#ffffff", INK, 0.8))
    if v.get("cigar"):
        out.append(p("M86 66 L100 62", "none", "#7a4a2a", 3, ' stroke-linecap="round"'))
        out.append(circle(101, 61.6, 2, "#ff8a3a"))
        out.append(p("M102 58 C106 52 100 48 106 40", "none", "#c9c2d6", 1.6, ' opacity="0.7"'))
    return "".join(out)


def shrouded_corpse(t, v, rng):
    cloth = v.get("shroud", KAFAN)
    shade = "#00000055" if cloth != KAFAN else KAFAN_SHADE
    body = ("M80 30 C94 30 100 42 98 54 C104 64 106 84 102 104 C100 114 94 120 90 124 L92 130 L68 130 L70 124 "
            "C66 120 60 114 58 104 C54 84 56 64 62 54 C60 42 66 30 80 30 Z")
    out = []
    if not v.get("bald") and not v.get("headless"):
        out.append(p("M76 32 L69 16 L80 26 L91 16 L84 32 Z", cloth, INK, 2))
    out.append(p(body, cloth, INK, 2.2))
    out.append(p("M64 70 L96 84 M62 88 L100 102 M66 106 L96 118", "none", shade, 1.4, ' opacity="0.6"'))
    out.append(p("M62 56 Q80 62 98 56 M70 122 Q80 126 90 122", "none", INK, 2))
    out.append(p("M78 60 l-6 8 M82 60 l6 8 M78 124 l-5 7 M82 124 l5 7", "none", INK, 1.6))
    if v.get("headless"):
        out.append(p("M66 44 Q80 36 94 44 Q80 52 66 44 Z", DARAH, INK, 1.6))
        out.append(p("M78 48 l0 10 M84 48 l1 8", "none", DARAH, 2, ' stroke-linecap="round"'))
    elif v.get("bald"):
        out.append(ellipse(80, 38, 13, 12, "#c9bfae", INK, 2))
        out.append(eyes(80, 40, 5, 2.1, t["danger"], glow=True))
        out.append(p("M75 47 Q80 50 85 47", "none", INK, 1.6))
    else:
        out.append(ellipse(80, 44, 9.5, 10, "#3a3446", INK, 1.8))
        out.append(eyes(80, 43, 4, 1.8, t["danger"], glow=True))
        out.append(ellipse(80, 49, 1.6, 2, "#0b0910"))
    out.append(p("M58 136 q4 -4 8 0 M94 136 q4 -4 8 0", "none", "#c9c2d6", 1.4, ' opacity="0.7"'))
    return "".join(out)


def fireball(t, v, rng, uid):
    flame = ("M80 26 C96 50 114 62 110 92 C108 116 94 128 80 128 C66 128 52 116 50 94 C48 74 64 66 68 46 "
             "C72 58 76 60 80 26 Z")
    inner = "M80 62 C90 76 98 86 96 102 C94 114 88 120 80 120 C72 120 66 114 64 102 C62 90 72 84 80 62 Z"
    out = [
        p(flame, f"url(#{uid}-fire)", INK, 2),
        p(inner, "#ffe39a", "none", extra=' opacity="0.85"'),
        eyes(80, 98, 7, 2.6, 5),
        p("M70 108 l4 4 l4 -4 l4 4 l4 -4 l4 4 l2 -4", "none", INK, 2),
    ]
    for _ in range(6):
        a = rng.uniform(-2.6, -0.5)
        r = rng.uniform(50, 62)
        out.append(circle(80 + math.cos(a) * r * 0.8, 92 + math.sin(a) * r, rng.uniform(1.2, 2.4), "#ffb347"))
    return "".join(out)


def giant(t, v, rng):
    skin = v.get("skin", "#8a4a3a")
    out = [
        p(blob(80, 46, 26, 24, 16, 0.16, rng), HAIR, INK, 1.4),
        p("M50 70 C44 80 44 100 52 112 L108 112 C116 100 116 80 110 70 C96 62 64 62 50 70 Z", skin, INK, 2.2),
        limb("M50 74 C38 86 36 100 40 114", skin, 9),
        limb("M110 74 C122 86 124 100 120 114", skin, 9),
        circle(40, 116, 6, skin, INK, 2), circle(120, 116, 6, skin, INK, 2),
        # Kain poleng: the black-and-white chequered cloth of Bali.
        f'<rect x="56" y="108" width="48" height="20" fill="url(#poleng)" stroke="{INK}" stroke-width="2"/>',
        limb("M68 128 L66 140", skin, 9), limb("M92 128 L94 140", skin, 9),
        ellipse(80, 54, 18, 17, skin, INK, 2.2),
        ellipse(72, 50, 5.5, 5.5, "#fff4d6", INK, 1.6), ellipse(88, 50, 5.5, 5.5, "#fff4d6", INK, 1.6),
        circle(72, 50, 2.4, DARAH if t["danger"] >= 4 else INK), circle(88, 50, 2.4, DARAH if t["danger"] >= 4 else INK),
        p("M66 43 L76 46 M94 43 L84 46", "none", INK, 2.4),
        p("M70 62 Q80 68 90 62 Q80 72 70 62 Z", "#5a1020", INK, 1.6),
        p("M71 62 l2 -6 l2 6 M85 62 l2 -6 l2 6", "#fff4d6", INK, 1),
        p("M66 32 l-6 -10 l10 6 Z M94 32 l6 -10 l-10 6 Z", PRADA, INK, 1.4),
    ]
    return "".join(out)


def winged(t, v, rng):
    if v.get("bat"):
        out = [
            bat_wing(-1, "#4a3a3a", "#9a7a6a", 66), bat_wing(1, "#4a3a3a", "#9a7a6a", 66),
            p(blob(80, 88, 14, 22, 14, 0.12, rng), "#6a5040", INK, 2),
            p(blob(80, 60, 14, 13, 12, 0.12, rng), "#6a5040", INK, 2),
            p("M68 50 L64 36 L74 48 Z M92 50 L96 36 L86 48 Z", "#6a5040", INK, 1.8),
            ellipse(80, 64, 8, 6, "#8f6c54", INK, 1.4),
            eyes(80, 58, 5, 2.2, t["danger"]),
            p("M75 67 l1.5 4 l1.5 -4 M82 67 l1.5 4 l1.5 -4", "#ffffff", INK, 0.8),
            p("M72 110 l-4 8 M88 110 l4 8", "none", INK, 2.4),
        ]
        return "".join(out)
    skin = "#9a5a52"
    out = [
        bat_wing(-1, "#5a2e3a", "#b07a86"), bat_wing(1, "#5a2e3a", "#b07a86"),
        p("M70 64 C66 80 68 96 72 104 L88 104 C92 96 94 80 90 64 C84 60 76 60 70 64 Z", skin, INK, 2),
        limb("M74 104 L72 128", skin, 6), limb("M86 104 L88 128", skin, 6),
        ellipse(80, 50, 11, 12, skin, INK, 2),
        p("M70 44 L64 32 L74 40 Z M90 44 L96 32 L86 40 Z", skin, INK, 1.6),
        eyes(80, 50, 4, 1.9, t["danger"]),
        p("M76 57 Q80 60 84 57", "none", INK, 1.6),
        p("M70 92 C64 102 70 112 64 118", "none", skin, 3, ' stroke-linecap="round"'),
    ]
    return "".join(out)


def tiger(t, v, rng):
    fur = "#c8702a"
    stripes = INK
    out = [
        p("M100 118 C122 118 126 98 116 88 C112 84 108 88 112 92", "none", INK, 7.4, ' stroke-linecap="round"'),
        p("M100 118 C122 118 126 98 116 88 C112 84 108 88 112 92", "none", fur, 5, ' stroke-linecap="round"'),
        p("M60 76 C54 92 56 112 62 126 L98 126 C104 112 106 92 100 76 C92 68 68 68 60 76 Z", fur, INK, 2.2),
        p("M70 86 C74 92 72 98 70 104 M90 86 C86 92 88 98 90 104 M64 108 l10 4 M96 108 l-10 4", "none", stripes, 2.2),
        ellipse(80, 110, 10, 14, "#f3e1c4", "none", extra=' opacity="0.9"'),
        limb("M62 80 C52 92 50 104 54 114", fur, 7), limb("M98 80 C108 92 110 104 106 114", fur, 7),
        p("M50 116 l-2 5 M54 117 l0 5 M58 116 l2 5 M102 116 l-2 5 M106 117 l0 5 M110 116 l2 5", "none", "#ffffff", 1.4),
        ellipse(70, 128, 10, 6, fur, INK, 2), ellipse(90, 128, 10, 6, fur, INK, 2),
        p("M64 40 L62 26 L74 34 Z M96 40 L98 26 L86 34 Z", fur, INK, 2),
        ellipse(80, 52, 18, 17, fur, INK, 2.2),
        p("M68 40 l4 6 M80 36 l0 7 M92 40 l-4 6 M63 52 l7 1 M97 52 l-7 1", "none", stripes, 2),
        ellipse(80, 60, 9, 7, "#f3e1c4", INK, 1.4),
        eyes(80, 50, 6, 2.1, max(t["danger"], 4)),
        p("M77 57 L83 57 L80 61 Z", INK),
        p("M80 61 L80 64 M74 64 Q80 68 86 64", "none", INK, 1.4),
    ]
    return "".join(out)


def elongated(t, v, rng):
    body = "#6d6385"
    out = [
        limb("M74 80 L68 132", body, 5), limb("M86 80 L92 132", body, 5),
        p("M72 36 C70 50 70 70 72 84 L88 84 C90 70 90 50 88 36 Z", body, INK, 2),
        limb("M72 40 C60 60 56 90 54 124", body, 3.6), limb("M88 40 C100 60 104 90 106 124", body, 3.6),
        limb("M80 36 L80 18", body, 4),
        ellipse(80, 12, 7, 8, body, INK, 2),
        eyes(80, 12, 3, 1.4, 4),
    ]
    return "".join(out)


def procession(t, v, rng):
    obj = v.get("object")
    mist = p("M20 118 C34 110 46 124 60 116 C74 108 84 122 100 114", "none", "#c9c2d6", 3, ' opacity="0.45" stroke-linecap="round"')
    if obj == "train":
        return "".join([
            mist,
            p("M40 120 L40 66 C40 56 50 50 62 50 L104 50 C116 50 122 58 122 68 L122 120 Z", "#3a4a5a", INK, 2.2),
            f'<rect x="52" y="60" width="18" height="16" rx="2" fill="{GLOW}" stroke="{INK}" stroke-width="1.6"/>',
            f'<rect x="92" y="60" width="18" height="16" rx="2" fill="{GLOW}" stroke="{INK}" stroke-width="1.6" opacity="0.5"/>',
            circle(81, 98, 9, "#fff2c0", INK, 2), circle(81, 98, 16, GLOW, extra=' opacity="0.25"'),
            p("M36 120 L126 120 M40 128 L122 128", "none", INK, 2.4),
            p("M44 124 l10 0 M70 124 l10 0 M96 124 l10 0", "none", "#8a8a8a", 3),
            p("M82 50 L82 40 M78 40 L86 40", "none", INK, 2.4),
            p("M84 36 C90 26 80 22 88 12", "none", "#c9c2d6", 3, ' opacity="0.6" stroke-linecap="round"'),
        ])
    if obj == "ambulance":
        return "".join([
            mist,
            p("M34 116 L34 70 L96 70 L112 86 L126 92 L126 116 Z", "#ece6dc", INK, 2.2),
            p("M98 74 L110 88 L98 88 Z", "#5a7a9a", INK, 1.6),
            p("M58 82 l8 0 l0 -8 l8 0 l0 8 l8 0 l0 8 l-8 0 l0 8 l-8 0 l0 -8 l-8 0 Z", DARAH, INK, 1),
            f'<rect x="58" y="62" width="14" height="8" rx="2" fill="{EYE_RED}" stroke="{INK}" stroke-width="1.4"/>',
            circle(65, 64, 18, EYE_RED, extra=' opacity="0.25"'),
            circle(52, 118, 8, INK), circle(52, 118, 3, "#8a8a8a"), circle(108, 118, 8, INK), circle(108, 118, 3, "#8a8a8a"),
        ])
    # Keranda: the Javanese bier, draped in green cloth, gliding with its bearers' mist.
    return "".join([
        mist,
        p("M40 96 C40 70 120 70 120 96 Z", "#2f6a46", INK, 2.2),
        p("M40 96 L120 96 L116 108 L44 108 Z", "#24503a", INK, 2),
        p("M46 92 C60 78 100 78 114 92", "none", PRADA, 2),
        "".join(circle(46 + i * 9, 100 + (i % 2) * 2, 1.8, "#ffffff", INK, 0.5) for i in range(9)),
        p("M50 108 L46 124 M110 108 L114 124 M30 102 L130 102", "none", "#7a5a3a", 3, ' stroke-linecap="round"'),
        p("M60 80 L60 64 M100 80 L100 64", "none", PRADA, 1.6),
        circle(60, 62, 2.4, PRADA), circle(100, 62, 2.4, PRADA),
    ])


def serpent(t, v, rng):
    scales = "#2f7a5a"
    coil = "M30 128 C30 108 70 112 80 120 C96 132 128 126 124 108 C120 92 92 98 84 100 C66 104 50 96 54 82 C58 70 74 72 82 74"
    out = [
        p(coil, "none", INK, 19, ' stroke-linecap="round"'),
        p(coil, "none", scales, 15.5, ' stroke-linecap="round"'),
        p(coil, "none", PRADA, 2, ' stroke-dasharray="3 5" opacity="0.8"'),
    ]
    if t["traits"].get("domain_human_like") == 1 or v.get("crown"):
        dress = v.get("dress", "#2f6e4a")
        out += [
            p("M70 76 C68 64 70 56 72 50 L88 50 C90 56 92 64 90 76 Z", dress, INK, 2),
            limb("M72 54 C64 62 62 70 64 78", KAFAN, 4), limb("M88 54 C96 62 98 70 96 78", KAFAN, 4),
            long_hair_head(80, 38, t["danger"], crown=True),
        ]
    else:
        out += [
            p("M74 74 C70 58 76 44 90 42 C104 40 110 50 104 58 C100 64 92 64 86 70 Z", scales, INK, 2.2),
            p("M86 44 L84 30 L92 40 L96 28 L98 42 L106 34 L102 48 Z", PRADA, INK, 1.4),
            eyes(96, 50, 0, 2.4, 4),
            p("M104 58 L114 62 M114 62 l4 -2 M114 62 l4 3", "none", DARAH, 1.6),
        ]
    return "".join(out)


def masked(t, v, rng):
    kind = v.get("mask")
    if kind == "rangda":
        hair = "#efe9df"
        out = [
            "".join(p(f"M80 40 C{80 + math.cos(a)*30:.0f} {50 + math.sin(a)*20:.0f} {80 + math.cos(a)*50:.0f} {80 + math.sin(a)*40:.0f} {80 + math.cos(a)*48:.0f} {130:.0f}", "none", hair, 3, ' stroke-linecap="round" opacity="0.9"') for a in [i * math.pi / 9 for i in range(10)]),
            ellipse(80, 66, 24, 26, "#f2e6cf", INK, 2.2),
            p("M60 44 l6 -14 l6 10 l8 -14 l8 14 l6 -10 l6 14 Z", PRADA, INK, 1.6),
            circle(69, 62, 7, "#ffffff", INK, 2), circle(91, 62, 7, "#ffffff", INK, 2),
            circle(69, 62, 3.4, DARAH), circle(91, 62, 3.4, DARAH),
            p("M68 80 Q80 74 92 80 L90 86 Q80 82 70 86 Z", INK),
            p("M70 80 l2 10 l2 -9 M86 81 l2 9 l2 -10", "#ffffff", INK, 1),
            p("M74 84 C72 100 82 112 76 132 C84 116 90 104 86 84 Z", DARAH, INK, 1.6),
            p("M79 100 C82 110 76 118 80 128", "none", PRADA, 1.4),
        ]
        return "".join(out)
    if kind == "barong":
        out = [
            p(blob(80, 76, 44, 40, 20, 0.1, rng), "#e8d8a8", INK, 1.6),
            ellipse(80, 72, 26, 24, "#b0302a", INK, 2.2),
            p("M54 50 C60 30 100 30 106 50 L98 46 L92 34 L86 46 L80 30 L74 46 L68 34 L62 46 Z", PRADA, INK, 1.6),
            circle(56, 50, 4, "#3a9a7a", INK, 1.2), circle(104, 50, 4, "#3a9a7a", INK, 1.2),
            circle(70, 66, 7.5, "#ffffff", INK, 2), circle(90, 66, 7.5, "#ffffff", INK, 2),
            circle(70, 66, 3.4, INK), circle(90, 66, 3.4, INK),
            p("M66 84 Q80 78 94 84 L92 92 Q80 88 68 92 Z", "#ffffff", INK, 1.6),
            p("M68 92 l2 6 l2 -6 M88 92 l2 6 l2 -6", "#ffffff", INK, 1),
            p("M64 76 C70 74 74 78 80 76 C86 78 90 74 96 76", "none", INK, 2.4),
            p("M60 104 C70 112 90 112 100 104 L96 120 L64 120 Z", "#c99a3a", INK, 1.6),
        ]
        return "".join(out)
    # Carved wooden mask (Dayak hudoq, Asmat, Toraja and Maluku ancestor masks).
    wood = "#8a5a34"
    out = [
        p("M54 42 C54 26 106 26 106 42 L104 100 C100 122 60 122 56 100 Z", wood, INK, 2.2),
        p("M62 40 C70 34 90 34 98 40 M60 106 C70 114 90 114 100 106", "none", "#e8dcc6", 2),
        p("M58 54 C64 46 76 48 78 58 C72 66 62 64 58 54 Z M102 54 C96 46 84 48 82 58 C88 66 98 64 102 54 Z", "#f2ead8", INK, 1.6),
        circle(68, 56, 3, INK), circle(92, 56, 3, INK),
        p("M80 60 L74 82 L86 82 Z", "#6a4024", INK, 1.6),
        p("M66 92 L94 92 L90 100 L70 100 Z", "#f2ead8", INK, 1.6),
        p("M70 92 l0 8 M75 92 l0 8 M80 92 l0 8 M85 92 l0 8 M90 92 l0 8", "none", INK, 1),
        p("M58 70 q6 4 0 8 q6 4 0 8 M102 70 q-6 4 0 8 q-6 4 0 8", "none", "#e8dcc6", 1.6),
        p("M54 30 C46 18 52 10 58 18 M106 30 C114 18 108 10 102 18", "none", "#e8dcc6", 2),
        "".join(p(f"M{58 + i*6} 116 l-2 {16 + (i % 3) * 4}", "none", "#c9b07a", 2) for i in range(8)),
    ]
    return "".join(out)


def witch(t, v, rng):
    cloak = "#4a2e4f"
    out = [
        p("M86 46 C104 54 110 80 106 112 C104 124 96 130 86 130 L58 130 C54 112 56 84 66 62 Z", cloak, INK, 2.2),
        p("M60 130 C58 110 62 90 70 74", "none", "#7a5a8a", 1.6),
        p("M66 40 C56 60 54 90 58 110 L70 108 C68 84 70 64 74 50 Z", "#e8e4dc", INK, 1.4),
        limb("M72 72 C60 80 50 88 46 96", "#c9a88a", 4),
        p("M44 70 L50 134", "none", "#6a4a2a", 3.4, ' stroke-linecap="round"'),
        circle(46, 96, 3.6, "#c9a88a", INK, 1.4),
        ellipse(76, 44, 11, 12, "#c9a88a", INK, 2),
        p("M66 36 C70 26 88 26 90 40 C86 34 72 34 66 42 Z", "#e8e4dc", INK, 1.4),
        eyes(73, 45, 3.6, 1.7, t["danger"]),
        p("M67 52 Q72 56 78 52", "none", INK, 1.6),
        p("M64 46 Q60 50 64 52", "none", INK, 1.6),
    ]
    if v.get("mask") == "rangda" or t["traits"].get("apotropaic_magic") == 1:
        out.append(circle(46, 96, 9, "#b06cff", extra=' opacity="0.35"'))
        out.append(circle(46, 96, 4.5, "#e0c8ff", extra=' opacity="0.8"'))
    return "".join(out)


def animal(t, v, rng):
    kind = v.get("animal") or ("crocodile" if "crocodile" in t["morphology"].lower() else
                               "horse" if "horse" in t["morphology"].lower() else "dog")
    if kind == "crocodile":
        hide = "#e9e4d6"
        return "".join([
            p("M24 112 C40 100 70 98 96 100 L132 104 C140 106 140 112 132 114 L96 118 C70 124 40 124 24 112 Z", hide, INK, 2.2),
            p("M30 112 C20 114 14 118 8 116", "none", INK, 6, ' stroke-linecap="round"'),
            p("M30 112 C20 114 14 118 8 116", "none", hide, 3.6, ' stroke-linecap="round"'),
            p("M96 110 L132 110", "none", INK, 1.4),
            p("M100 110 l2 3 l2 -3 M108 110 l2 3 l2 -3 M116 110 l2 3 l2 -3", "#ffffff", INK, 0.8),
            "".join(p(f"M{40 + i*10} 104 l4 -5 l4 5", "none", KAFAN_SHADE, 1.6) for i in range(5)),
            limb("M48 118 L44 130", hide, 5), limb("M84 118 L88 130", hide, 5),
            circle(98, 102, 3, EYE_RED), circle(98, 102, 6, EYE_RED, extra=' opacity="0.3"'),
        ])
    if kind == "horse":
        skin = "#5a4232"
        return "".join([
            limb("M72 96 L66 132", skin, 7), limb("M88 96 L94 132", skin, 7),
            p("M64 60 C60 76 62 92 68 100 L92 100 C98 92 100 76 96 60 C88 54 72 54 64 60 Z", skin, INK, 2.2),
            limb("M64 62 C52 76 48 96 50 118", skin, 5), limb("M96 62 C108 76 112 96 110 118", skin, 5),
            p("M72 58 C66 46 66 30 74 22 C82 16 92 22 92 32 C92 42 90 50 86 58 Z", skin, INK, 2.2),
            p("M74 22 C70 30 64 34 60 44 C66 40 70 38 72 40", HAIR, INK, 1.2),
            p("M74 22 L72 12 L78 20 Z", skin, INK, 1.6),
            circle(84, 30, 2, EYE_RED), ellipse(88, 52, 4, 3, "#3a2a20"),
        ])
    coat = {"boar": "#6a5a66", "cat": "#5a5070", "dog": "#6a5a52"}[kind]
    out = [
        p("M42 96 C34 90 30 80 34 72", "none", INK, 5.4, ' stroke-linecap="round"'),
        p("M42 96 C34 90 30 80 34 72", "none", coat, 3, ' stroke-linecap="round"'),
        limb("M56 104 L54 128", coat, 6), limb("M70 106 L70 130", coat, 6),
        limb("M94 106 L94 130", coat, 6), limb("M106 102 L110 128", coat, 6),
        p(blob(80, 96, 34, 15, 16, 0.08, rng), coat, INK, 1.8),
    ]
    if kind == "boar":
        out.append(p("M60 84 C66 74 92 74 100 84 L96 96 L64 96 Z", "#1d1626", INK, 1.2))
    if v.get("headless"):
        out.append(ellipse(112, 88, 5, 7, DARAH, INK, 1.6))
        return "".join(out)
    hx, hy = 116, 84
    out.append(p(blob(hx, hy, 14, 12, 10, 0.08, rng), coat, INK, 1.8))
    if kind == "boar":
        out += [ellipse(hx + 12, hy + 4, 6, 5, "#5a4a5a", INK, 1.4), circle(hx + 12, hy + 3, 1, INK), circle(hx + 13.5, hy + 5, 1, INK),
                p(f"M{hx+6} {hy+8} l4 -8 M{hx+10} {hy+9} l4 -7", "none", "#f3ead6", 2, ' stroke-linecap="round"'),
                p(f"M{hx-8} {hy-8} l-2 -8 l8 4 Z", coat, "#8a7a96", 1.2)]
    else:
        out += [p(f"M{hx-10} {hy-6} l-2 -12 l8 6 Z M{hx+2} {hy-10} l4 -12 l4 10 Z", coat, "#8a7a96", 1.2)]
    out += [circle(hx - 2, hy - 1, 2.2, EYE_RED), circle(hx + 6, hy - 1, 2.2, EYE_RED),
            circle(hx - 2, hy - 1, 5, EYE_RED, extra=' opacity="0.25"'), circle(hx + 6, hy - 1, 5, EYE_RED, extra=' opacity="0.25"')]
    return "".join(out)


def wisp(cx, cy, s, tint, danger, opacity=0.92):
    d = (f"M{cx-14*s} {cy+10*s} C{cx-18*s} {cy-20*s} {cx+18*s} {cy-20*s} {cx+14*s} {cy+10*s} "
         f"C{cx+18*s} {cy+40*s} {cx+22*s} {cy+60*s} {cx+30*s} {cy+76*s} "
         f"C{cx+16*s} {cy+70*s} {cx+8*s} {cy+78*s} {cx-2*s} {cy+72*s} "
         f"C{cx-10*s} {cy+80*s} {cx-20*s} {cy+72*s} {cx-24*s} {cy+66*s} "
         f"C{cx-18*s} {cy+50*s} {cx-16*s} {cy+30*s} {cx-14*s} {cy+10*s} Z")
    return "".join([
        p(d, tint, INK, 2, f' opacity="{opacity}"'),
        p(f"M{cx-14*s} {cy+18*s} C{cx-26*s} {cy+28*s} {cx-30*s} {cy+38*s} {cx-28*s} {cy+44*s}", "none", INK, 1.8),
        p(f"M{cx+14*s} {cy+18*s} C{cx+26*s} {cy+28*s} {cx+30*s} {cy+38*s} {cx+28*s} {cy+44*s}", "none", INK, 1.8),
        eyes(cx, cy, 5 * s, 2.2 * s, danger),
        ellipse(cx, cy + 9 * s, 2.4 * s, 3.4 * s, INK),
    ])


def humanoid_spirit(t, v, rng):
    tint = "#e6e2f2"
    kind = v.get("spirit")
    out = []
    if kind == "sun":
        out += [circle(80, 46, 26, PRADA, extra=' opacity="0.35"'), circle(80, 46, 18, "#ffd27a", extra=' opacity="0.6"')]
        out += ["".join(p(f"M{80 + math.cos(a)*22:.1f} {46 + math.sin(a)*22:.1f} L{80 + math.cos(a)*32:.1f} {46 + math.sin(a)*32:.1f}", "none", PRADA, 2, ' stroke-linecap="round"') for a in [i * math.pi / 6 for i in range(12)])]
    if kind == "waruga":
        out += [
            p("M50 104 L110 104 L110 134 L50 134 Z", "#7a7468", INK, 2),
            p("M44 104 L80 82 L116 104 Z", "#8a8478", INK, 2),
            p("M58 114 q6 6 12 0 q6 6 12 0 q6 6 12 0 q6 6 12 0", "none", INK, 1.4),
        ]
        out.append(wisp(80, 46, 0.62, tint, t["danger"], 0.8))
        return "".join(out)
    if kind == "shrine":
        out.append(p("M100 132 L100 104 L96 104 L110 92 L124 104 L120 104 L120 132 Z", "#5a4a3a", INK, 1.8))
        out.append(circle(110, 114, 3, GLOW))
    if kind == "double":
        out.append(wisp(96, 48, 0.82, "#9a94b6", t["danger"], 0.55))
        out.append(wisp(70, 48, 0.82, tint, t["danger"]))
        return "".join(out)
    if kind == "bunian":
        out.append(wisp(80, 44, 0.95, "#f0e6c8", t["danger"]))
        out.append(p("M66 36 C70 24 90 24 94 36 L90 32 L80 36 L70 32 Z", PRADA, INK, 1.4))
        return "".join(out)
    out.append(wisp(80, 44, 1.0, tint, t["danger"]))
    if kind == "leaves":
        out.append("".join(p(f"M{80 + (i-2)*8} 30 c-4 -8 4 -14 0 -20 c6 4 6 14 0 20 Z", "#4f8a3a", INK, 1) for i in range(5)))
    if kind == "dog":
        out.append(p(blob(118, 120, 12, 7, 10, 0.08, rng), "#5a5070", INK, 1.2))
        out.append(p("M126 116 l6 -4 l2 6 Z", "#5a5070", INK, 1.2))
        out.append(circle(128, 116, 1.6, EYE_RED))
    if kind == "keris":
        out.append(p("M112 60 q-4 8 2 14 q-6 6 0 14 q-6 6 0 14 L114 112 L118 102 q-4 -8 2 -14 q-6 -6 0 -14 q-6 -6 0 -14 Z", "#b9b2a6", INK, 1.4))
        out.append(p("M108 112 L124 112 L116 128 Z", PRADA, INK, 1.4))
    return "".join(out)


def aquatic(t, v, rng):
    body = "#bcd6d0"
    out = [
        p("M66 40 C58 62 56 88 60 104 L100 104 C104 88 102 62 94 40 Z", HAIR, INK, 1.5),
        p("M66 64 C62 80 62 96 64 110 L96 110 C98 96 98 80 94 64 C88 58 72 58 66 64 Z", body, INK, 2),
        limb("M68 68 C58 76 54 86 52 96", body, 4), limb("M92 68 C102 76 106 86 108 96", body, 4),
        long_hair_head(80, 46, t["danger"], v.get("crown", False), face=body),
        "".join(p(f"M{62 + i*9} {60 + (i % 3) * 14} l0 6", "none", "#7ab6d6", 1.6, ' stroke-linecap="round"') for i in range(5)),
    ]
    return "".join(out)


def child(t, v, rng):
    skin = "#b9c0a8"
    out = [
        limb("M72 108 L70 128", skin, 6), limb("M88 108 L90 128", skin, 6),
        p("M66 80 C62 92 64 104 70 110 L90 110 C96 104 98 92 94 80 C88 74 72 74 66 80 Z" if not v.get("belly") else
          "M66 80 C54 92 58 112 70 114 L90 114 C102 112 106 92 94 80 C88 74 72 74 66 80 Z", skin, INK, 2),
        p("M66 104 L94 104 L90 114 L70 114 Z", "#3a3036", INK, 1.6),
        limb("M68 84 C60 90 58 98 58 104", skin, 4.5), limb("M92 84 C100 90 102 98 102 104", skin, 4.5),
        p("M56 54 L44 44 L58 50 Z M104 54 L116 44 L102 50 Z", skin, INK, 1.8),
        ellipse(80, 56, 22, 22, skin, INK, 2.2),
        ellipse(72, 56, 5, 6, "#ffffff", INK, 1.4), ellipse(88, 56, 5, 6, "#ffffff", INK, 1.4),
        circle(72, 57, 2.6, INK), circle(88, 57, 2.6, INK),
        p("M74 68 Q80 72 86 68", "none", INK, 1.6),
        p("M76 69 l1 2.6 l1 -2.4 M82 69 l1 2.4 l1 -2.6", "#ffffff", INK, 0.6),
    ]
    if v.get("belly"):
        out.append(p("M74 98 Q80 102 86 98", "none", INK, 1.2))
    return "".join(out)


def hungry_ghost(t, v, rng):
    skin = "#9aa0b8"
    out = [
        limb("M72 112 L66 134", skin, 3), limb("M88 112 L94 134", skin, 3),
        ellipse(80, 96, 26, 22, skin, INK, 2.2),
        p("M68 92 Q80 100 92 92", "none", INK, 1.2),
        limb("M66 82 C54 90 48 100 46 114", skin, 2.6), limb("M94 82 C106 90 112 100 114 114", skin, 2.6),
        limb("M80 74 L80 54", skin, 2.6),
        ellipse(80, 44, 12, 13, skin, INK, 2),
        ellipse(76, 40, 3.6, 4.6, INK), ellipse(84, 40, 3.6, 4.6, INK),
        circle(76, 41, 1.2, "#ffd27a"), circle(84, 41, 1.2, "#ffd27a"),
        circle(80, 52, 1, INK),
        p("M72 34 C76 28 84 28 88 34", "none", INK, 1.2),
    ]
    return "".join(out)


# ---- Scenery from traits ----------------------------------------------------

def banyan(x, rng):
    roots = "".join(p(f"M{x + i*7 - 20} 50 C{x + i*7 - 22} 80 {x + i*7 - 18} 100 {x + i*7 - 20 + rng.uniform(-3,3):.1f} 134", "none", "#3d5244", 1.4) for i in range(7))
    return (p(f"M{x-6} 134 C{x-4} 110 {x-6} 80 {x-2} 56 L{x+6} 56 C{x+8} 80 {x+6} 110 {x+10} 134 Z", "#33443a", "none")
            + p(blob(x, 36, 34, 22, 14, 0.12, rng), "#2c3d33", "none") + roots)


def house(x):
    return (p(f"M{x-24} 134 L{x-24} 104 L{x+24} 104 L{x+24} 134 Z", "#3a3150", INK, 1.2)
            + p(f"M{x-34} 106 L{x-14} 86 L{x-8} 74 L{x+8} 74 L{x+14} 86 L{x+34} 106 Z", "#4a3d62", INK, 1.2)
            + f'<rect x="{x-6}" y="112" width="10" height="10" fill="{GLOW}" opacity="0.85"/>'
            + circle(x - 1, 117, 12, GLOW, extra=' opacity="0.12"'))


def graves(x, rng):
    out = []
    for i, dx in enumerate((-12, 10)):
        h = 18 + i * 6
        out.append(p(f"M{x+dx-5} 134 L{x+dx-5} {134-h} Q{x+dx} {128-h-8} {x+dx+5} {134-h} L{x+dx+5} 134 Z", "#4a4458", INK, 1.2))
    # Kamboja (frangipani): the cemetery flower of Java and Bali.
    for fx, fy in ((x - 20, 130), (x + 20, 132), (x, 136)):
        out.append("".join(ellipse(fx + math.cos(a) * 2.6, fy + math.sin(a) * 2.6, 2.4, 1.4, "#fff8ec", extra=f' transform="rotate({math.degrees(a):.0f} {fx + math.cos(a)*2.6:.1f} {fy + math.sin(a)*2.6:.1f})"') for a in [i * 2 * math.pi / 5 for i in range(5)]))
        out.append(circle(fx, fy, 1.2, "#f2c14e"))
    return "".join(out)


def waves():
    return "".join(
        p(f"M0 {126 + i*8} " + " ".join(f"q10 {-6 + (i % 2) * 2} 20 0" for _ in range(9)) + " L160 160 L0 160 Z", c, "none", extra=f' opacity="{o}"')
        for i, (c, o) in enumerate([("#1f4a5a", 0.9), ("#2a6476", 0.85), ("#3a7e8e", 0.8)])
    )


def coins(x, y):
    # Kepeng: the holed copper-alloy coins still used in Balinese offerings.
    return "".join(circle(x + dx, y + dy, 5, PRADA, INK, 1.2) + f'<rect x="{x+dx-1.6}" y="{y+dy-1.6}" width="3.2" height="3.2" fill="{INK}"/>' for dx, dy in ((0, 0), (9, 2), (4, -6)))


def incense(x, y):
    return (p(f"M{x-8} {y} L{x+8} {y} L{x+5} {y+8} L{x-5} {y+8} Z", "#6a4a2a", INK, 1.2)
            + circle(x, y - 1, 2, "#ff8a3a")
            + p(f"M{x} {y-3} C{x+6} {y-12} {x-6} {y-18} {x+2} {y-28} C{x+8} {y-36} {x} {y-42} {x+4} {y-50}", "none", "#c9c2d6", 2, ' opacity="0.55" stroke-linecap="round"'))


def bundle(x, y):
    return (ellipse(x, y, 9, 5.5, KAFAN, INK, 1.2) + circle(x + 6, y - 1, 3.2, "#d8c8b0", INK, 1)
            + p(f"M{x-4} {y-4} L{x-4} {y+4} M{x} {y-5} L{x} {y+5}", "none", KAFAN_SHADE, 1))


def blood(x, y):
    return ellipse(x, y + 2, 9, 2.6, DARAH, extra=' opacity="0.8"') + "".join(
        p(f"M{x+dx} {y-10+dy} q-2.6 4 0 5.4 q2.6 -1.4 0 -5.4 Z", DARAH) for dx, dy in ((-4, 0), (3, -6), (6, 2)))


FIGURES = {
    "spectral_female": spectral_female, "flying_head": flying_head, "upper_torso": upper_torso,
    "primate": primate, "shrouded_corpse": shrouded_corpse, "giant": giant, "winged": winged,
    "tiger": tiger, "elongated": elongated, "procession": procession, "serpent": serpent,
    "masked": masked, "witch": witch, "animal": animal, "aquatic": aquatic, "child": child,
    "hungry_ghost": hungry_ghost,
}


def draw(t: dict) -> str:
    uid = "g" + hashlib.sha1(t["id"].encode()).hexdigest()[:6]
    rng = random.Random(int(hashlib.sha1(t["id"].encode()).hexdigest(), 16))
    v = dict(VISUAL.get(t["id"], {}))
    plan = v.get("plan", t["bodyPlan"])
    tr = t["traits"]
    ring = CLADE_RING[C.CLADES.index(t["clade"])]

    if plan == "fireball":
        figure = fireball(t, v, rng, uid)
    elif plan == "humanoid_spirit":
        figure = humanoid_spirit(t, v, rng)
    else:
        figure = FIGURES[plan](t, v, rng)

    flies = tr.get("locomotion_flight") == 1 and plan not in ("procession", "animal", "serpent", "masked")
    scale = v.get("scale", 1.0) * rng.uniform(0.96, 1.03)
    tilt = rng.uniform(-4, 4)
    lift = -8 if flies else 0
    figure = (f'<g transform="translate(80 {134 + lift}) rotate({tilt:.1f}) scale({scale:.3f}) translate(-80 -134)">'
              f"{figure}</g>")

    # Sky: stars and a moon, placed by the seed.
    sky = []
    for _ in range(rng.randint(6, 11)):
        sky.append(circle(rng.uniform(18, 142), rng.uniform(14, 70), rng.uniform(0.5, 1.3), "#f4ecd6", extra=f' opacity="{rng.uniform(0.4, 0.9):.2f}"'))
    mx, my = rng.choice([(118, 34), (42, 32), (124, 46)])
    sky.append(circle(mx, my, 11, "#f4ecd6", extra=' opacity="0.9"'))
    sky.append(circle(mx + rng.choice([-5, 5]), my - 3, 10, f"url(#{uid}-sky)"))

    back = []
    left_used = right_used = False
    if tr.get("forest_association") == 1:
        back.append(banyan(30, rng))
        left_used = True
    if tr.get("domestic_settlement") == 1:
        back.append(house(128))
        right_used = True
    if tr.get("burial_association") == 1 and plan != "procession":
        if not right_used:
            back.append(graves(126, rng)); right_used = True
        elif not left_used:
            back.append(graves(34, rng)); left_used = True

    aura = []
    if tr.get("fire_luminosity") == 1 or plan == "fireball":
        aura.append(circle(80, 84, 56, f"url(#{uid}-glow)"))
    elif t["danger"] >= 5:
        aura.append(circle(80, 84, 52, f"url(#{uid}-dread)"))

    ground = [ellipse(80, 138, 30 if not flies else 18, 4, "#000000", extra=' opacity="0.35"')]
    front = []
    if tr.get("aquatic_association") == 1:
        front.append(waves())
    props = []
    if tr.get("theft_mischief") == 1:
        props.append(lambda x: coins(x, 132))
    if tr.get("apotropaic_magic") == 1 and plan != "witch":
        props.append(lambda x: incense(x, 126))
    if tr.get("child_association") == 1 and plan not in ("child", "spectral_female"):
        props.append(lambda x: bundle(x, 134))
    if tr.get("predation_blood_organs") == 1 and plan not in ("flying_head", "upper_torso"):
        props.append(lambda x: blood(x, 134))
    for fn, x in zip(props[:2], (36, 124) if not right_used else (36, 110)):
        front.append(fn(x))

    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160" role="img" aria-labelledby="{uid}-t">
<title id="{uid}-t">{_esc(t['name'])}, {_esc(t['morphology'].lower())}</title>
<defs>
<radialGradient id="{uid}-sky" cx="50%" cy="40%" r="75%"><stop offset="0" stop-color="#2d2547"/><stop offset="1" stop-color="#110e1b"/></radialGradient>
<radialGradient id="{uid}-glow"><stop offset="0" stop-color="#ffb347" stop-opacity="0.75"/><stop offset="1" stop-color="#ff6a2a" stop-opacity="0"/></radialGradient>
<radialGradient id="{uid}-dread"><stop offset="0" stop-color="{DARAH}" stop-opacity="0.55"/><stop offset="1" stop-color="{DARAH}" stop-opacity="0"/></radialGradient>
<linearGradient id="{uid}-fire" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#ffcf5a"/><stop offset="0.6" stop-color="#ff7a2a"/><stop offset="1" stop-color="#c8202a"/></linearGradient>
<pattern id="poleng" width="8" height="8" patternUnits="userSpaceOnUse"><rect width="8" height="8" fill="#f2ead8"/><rect width="4" height="4" fill="{INK}"/><rect x="4" y="4" width="4" height="4" fill="{INK}"/></pattern>
<clipPath id="{uid}-disc"><circle cx="80" cy="80" r="76"/></clipPath>
</defs>
<g clip-path="url(#{uid}-disc)">
<rect width="160" height="160" fill="url(#{uid}-sky)"/>
{''.join(sky)}
{''.join(back)}
{''.join(aura)}
{''.join(ground)}
{figure}
{''.join(front)}
</g>
<circle cx="80" cy="80" r="76" fill="none" stroke="{ring}" stroke-width="4"/>
</svg>
"""


def _esc(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def run(taxa: list[dict]) -> None:
    C.WEB_SVG.mkdir(parents=True, exist_ok=True)
    manual = C.ROOT / "assets" / "ghosts"
    n_manual = 0
    for t in taxa:
        out = C.WEB_SVG / f"{t['id']}.svg"
        hand = manual / f"{t['id']}.svg"
        if hand.exists():
            shutil.copyfile(hand, out)
            n_manual += 1
        else:
            out.write_text(draw(t))
    # Drop plates for taxa that were renamed or removed from the source.
    ids = {t["id"] for t in taxa}
    for old in C.WEB_SVG.glob("*.svg"):
        if old.stem not in ids:
            old.unlink()
    print(f"svg: {len(taxa)} plates ({n_manual} hand-drawn) -> {C.WEB_SVG.relative_to(C.ROOT)}")
