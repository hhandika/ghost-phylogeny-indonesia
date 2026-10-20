/**
 * Typed access to the pipeline output (src/data/phylogeny.json, written by
 * `uv run ghostphylo export`). Nothing here is hand-maintained data.
 */
import raw from "../data/phylogeny.json";

export type Coding = "source" | "filled" | "new";

export interface Ghost {
  id: string;
  name: string;
  region: string;
  regionGroup: string;
  culture: string | null;
  clade: string;
  morphology: string;
  bodyPlan: string;
  diet: string;
  dietClass: string | null;
  danger: number;
  origin: string | null;
  appearance: string | null;
  behavior: string | null;
  deterrents: string | null;
  popCulture: string | null;
  outgroup: boolean;
  inSourceTree: boolean;
  coding: Coding;
  traits: Record<string, number | null>;
  row: string;
  twins: string[];
  relatives: string[];
}

export interface Character {
  id: string;
  label: string;
  states: string[];
}

export interface TreeNode {
  id?: string;
  l: number;
  s?: number;
  c?: TreeNode[];
}

export interface Meta {
  title: string;
  source: string;
  generated: string;
  taxa: number;
  outgroups: number;
  characters: number;
  uniqueRows: number;
  outgroupMonophyletic: boolean;
  nodes: number;
  strongNodes: number;
  weakNodes: number;
  analysis: {
    software: string;
    model: string | null;
    logLikelihood: number | null;
    bic: number | null;
    parsimonyInformative: number | null;
    constantSites: number | null;
    bootstrap: string;
    seed: number;
  };
}

export interface Dataset {
  meta: Meta;
  clades: string[];
  regions: string[];
  bodyPlans: { id: string; label: string }[];
  characters: Character[];
  symbols: string;
  tree: TreeNode;
  ghosts: Ghost[];
}

export const data = raw as unknown as Dataset;
export const ghosts = data.ghosts;
export const byId = new Map(ghosts.map((g) => [g.id, g]));

/** Clade colour as a CSS variable (defined in styles/tailwind.css). */
export const cladeVar = (clade: string, clades = data.clades) =>
  `var(--clade-${clades.indexOf(clade)})`;

export const DANGER = ["", "Benign", "Unsettling", "Frightening", "Dangerous", "Lethal"];

export const CODING_LABEL: Record<Coding, string> = {
  source: "Coded in the source matrix",
  filled: "Some traits filled by folklore synthesis",
  new: "New entry coded by folklore synthesis",
};

/** Prefix a site path with the deploy base (GitHub Pages serves under /<repo>/). */
export const withBase = (path: string, base = import.meta.env.BASE_URL) =>
  `${base.replace(/\/$/, "")}/${path.replace(/^\//, "")}`;

export const plateUrl = (id: string, base?: string) => withBase(`ghosts/${id}.svg`, base);

/** Present traits in plain words, for chips and summaries. */
export const presentTraits = (g: Ghost, chars = data.characters) =>
  chars
    .slice(0, 18)
    .filter((c) => c.id !== "sex" && g.traits[c.id] === 1)
    .map((c) => c.label);

export const sexLabel = (g: Ghost) =>
  g.traits.sex === 1 ? "Female" : g.traits.sex === 0 ? "Male" : "Unspecified";
