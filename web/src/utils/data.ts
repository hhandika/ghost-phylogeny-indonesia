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

export interface KeyLead {
  char: string;
  /** State labels (English; translate with tr). With `not`, every state but these. */
  states: string[];
  not: boolean;
  /** The next couplet, or the ghosts this lead ends in. */
  to?: number;
  ghosts?: string[];
}

export interface Couplet {
  n: number;
  from: number | null;
  leads: [KeyLead, KeyLead];
}

export interface DichotomousKey {
  characters: { id: string; label: string }[];
  couplets: Couplet[];
  /** Ghost id to the couplets where it keys out. */
  index: Record<string, number[]>;
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
  key: DichotomousKey;
}

export const data = raw as unknown as Dataset;
export const ghosts = data.ghosts;
export const byId = new Map(ghosts.map((g) => [g.id, g]));

/** Clade color as a CSS variable (defined in styles/tailwind.css). */
export const cladeVar = (clade: string, clades = data.clades) =>
  `var(--clade-${clades.indexOf(clade)})`;

/** Prefix a site path with the deploy base (GitHub Pages serves under /<repo>/). */
export const withBase = (path: string, base = import.meta.env.BASE_URL) =>
  `${base.replace(/\/$/, "")}/${path.replace(/^\//, "")}`;

export const plateUrl = (id: string, base?: string) => withBase(`ghosts/${id}.svg`, base);
