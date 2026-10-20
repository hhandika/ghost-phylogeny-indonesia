# ghost-phylogeny-indonesia

This is the actual ghost phylogeny. Literally, not conceptually...

A comparative dataset of 110 Indonesian ghosts, spirits, and cryptids (plus outgroups from Malaysia, the Philippines, Thailand, Cambodia, and South Asia), scored like specimens on a morphological character matrix. IQ-TREE infers how they are related, and an interactive site shows the result.

## Layout

| Path | What it holds |
|---|---|
| `data/indonesian-ghosts-comprehensive-dataset.xlsx` | Source workbook (v3). Edited by hand. |
| `data/translations/id.json` | Curated Indonesian translations of every text value in the data. Edited by hand. |
| `ghostphylo/` | Python pipeline: parse → encode → infer → export → draw. |
| `data/processed/` | Cleaned taxon table, character matrix (`ghosts.nex`, `ghosts.phy`), character definitions. Generated. |
| `results/iqtree/` | IQ-TREE output, plus `ghosts.rooted.tre` (rooted on the outgroups, ladderized). Generated. |
| `assets/ghosts/` | Optional hand-drawn plates; `<taxon_id>.svg` here replaces the generated one. |
| `web/` | Astro + Bun + Tailwind site. `web/src/data/phylogeny.json` and `web/public/ghosts/*.svg` are generated. |
| `.github/workflows/phylogeny.yml` | Reruns the pipeline, builds the site, and deploys to GitHub Pages. |

## Pipeline

Requires [uv](https://docs.astral.sh/uv/) and [IQ-TREE](http://www.iqtree.org/) 2 or 3 on `PATH` (or set `$IQTREE`).

```bash
uv run ghostphylo all        # every step below
uv run ghostphylo parse      # workbook → data/processed/ghosts.{json,csv}
uv run ghostphylo encode     # → ghosts.nex, ghosts.phy, characters.csv
uv run ghostphylo tree       # IQ-TREE: -st MORPH -m MFP -B 1000 -bnni --seed 20261020
uv run ghostphylo export     # root, ladderize → web/src/data/phylogeny.json
uv run ghostphylo svg        # one plate per ghost → web/public/ghosts/
```

### Characters

Characters 1–18 are the workbook's coded traits (0 absent, 1 present, 2 variable; for sex, 1 female and 2 male or unspecified). Character 19 is the body plan and 20 the diet, each one unordered multistate character. Clade is left out because it is the grouping the tree tests. See `data/processed/characters.csv` for every state.

Parsing also cleans the workbook: clade spellings are merged (`ElementalDemonic` → `Elemental / Demonic`), fused words from lost slashes are restored (`Echoing laughweeping` → `Echoing laugh or weeping`), origins misfiled as deterrents in the original 61 rows are moved back, and boilerplate text is dropped.

### Caveats

Most codings beyond the original 61 taxa come from folklore synthesis rather than primary ethnography; the site marks them with ◆. Folklore spreads by film, trade, and religion as well as by descent, so read the tree as a map of resemblance among tellings.

## Site

*Ghost phylogeny, literally.* A spooky Indonesian theme: frosted-glass panels over a fixed night scene (a smoking volcano under the moon, a ruined *rumah panggung* with something pale in the window, a banyan and *nisan* gravestones, and a camp with a tent and campfire), with a batik *kawung* texture on the header and footer and a wayang *gunungan* mark. Light mode is a misty dusk; dark mode is night.

- **Atlas** (`/atlas`): rectangular tree, aligned trait matrix, sticky detail card.
- **Lantern** (`/lantern`): circular tree on a night canvas, the selected ghost lit at its centre.
- **Bestiary** (`/bestiary`): filterable field guide with side-by-side comparison.
- **Patterns** (`/patterns`): the rest of the dataset, each part in a different form: an archipelago bubble map with Pleistocene sea levels (today, −40, −80, −120 m) and Wallace's, Huxley's, Weber's, and Lydekker's lines, a clade × trait heatmap, a danger chart built from the plates, a body plan × diet bubble matrix, a support histogram, indistinguishable "twins", and coding provenance. Every chart has a data table.
- **Specimen pages** (`/ghosts/<taxon_id>`): every field and coded character for one ghost.

**Languages.** The site is bilingual: American English at `/…` and Indonesian at `/id/…`, with an EN | ID switcher in the header that keeps you on the same page. Interface strings live in `web/src/i18n/index.ts`. Text from the data (clades, traits, origins, behaviors, deterrents, and so on) is translated through `data/translations/id.json`; `ghostphylo export` embeds the strings the site uses and lists any that are missing, which then fall back to English. Parsing also converts the workbook's British spellings to American.

Accessibility targets WCAG 2.2 AA: text on glass keeps at least 4.5:1 against the darkest and brightest parts of the scene, controls have 3:1 boundaries, trait states differ in shape as well as colour, interactive trees are keyboard operable with announced selections, scrollable regions are focusable, and scene motion stops under `prefers-reduced-motion`. The Patterns map uses Natural Earth coastlines and NOAA ETOPO1 shelf outlines (both public domain), with line placements after hhandika-com's speciation map.

```bash
cd web
bun install
bun run dev      # http://localhost:4321
bun run build    # astro check + static build to web/dist/
```

## Deployment

Enable GitHub Pages once under **Settings → Pages → Source: GitHub Actions**. Each push to `main` that touches the data, pipeline, or site reruns the analysis, writes a summary of the model and any changed outputs to the run page, uploads the analysis files as an artifact, and deploys the site. Pull requests run the analysis and build without deploying.
