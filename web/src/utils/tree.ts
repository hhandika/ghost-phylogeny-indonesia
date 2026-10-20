/**
 * Tree layout shared by the three designs. The tree arrives rooted and
 * ladderized from the pipeline; this only assigns coordinates.
 */
import type { TreeNode } from "./data";

export interface Placed {
  id?: string;
  /** Distance from the root: branch-length sum or node depth. */
  x: number;
  /** Tip index, or the mean of the children's for internal nodes. */
  y: number;
  support?: number;
  parent: Placed | null;
  children: Placed[];
  /** Clade shared by every tip below, or null when mixed. */
  clade: string | null;
  tips: string[];
}

export type Mode = "cladogram" | "phylogram";

export function layout(tree: TreeNode, cladeOf: (id: string) => string, mode: Mode = "cladogram") {
  let row = 0;
  const all: Placed[] = [];
  const build = (n: TreeNode, parent: Placed | null, depth: number): Placed => {
    const p: Placed = {
      id: n.id,
      x: mode === "phylogram" ? (parent ? parent.x : 0) + (parent ? n.l : 0) : depth,
      y: 0,
      support: n.s,
      parent,
      children: [],
      clade: null,
      tips: [],
    };
    all.push(p);
    if (n.c) {
      p.children = n.c.map((c) => build(c, p, depth + 1));
      p.y = (p.children[0].y + p.children[p.children.length - 1].y) / 2;
      p.tips = p.children.flatMap((c) => c.tips);
      const clades = new Set(p.children.map((c) => c.clade));
      p.clade = clades.size === 1 ? [...clades][0] : null;
    } else {
      p.y = row++;
      p.tips = [n.id!];
      p.clade = cladeOf(n.id!);
    }
    return p;
  };
  const root = build(tree, null, 0);

  // Cladogram: tips line up at the right; internal nodes sit one step left of
  // their deepest child so the tree reads as nested brackets.
  if (mode === "cladogram") {
    const height = (p: Placed): number => (p.children.length ? 1 + Math.max(...p.children.map(height)) : 0);
    const H = height(root);
    for (const p of all) p.x = H - height(p);
  }
  const tips = all.filter((p) => !p.children.length);
  const maxX = Math.max(...tips.map((t) => t.x));
  return { root, all, tips, maxX, nTips: tips.length };
}

/** Elbow path for a rectangular tree. */
export const elbow = (p: Placed, sx: (x: number) => number, sy: (y: number) => number) =>
  p.parent ? `M${sx(p.parent.x)} ${sy(p.y)} H${sx(p.x)}` : "";

/** Vertical connector spanning an internal node's children. */
export const connector = (p: Placed, sx: (x: number) => number, sy: (y: number) => number) =>
  p.children.length ? `M${sx(p.x)} ${sy(p.children[0].y)} V${sy(p.children[p.children.length - 1].y)}` : "";

/** Polar helpers for the radial design. */
export const polar = (angle: number, r: number, cx = 0, cy = 0): [number, number] => [
  cx + r * Math.cos(angle),
  cy + r * Math.sin(angle),
];

export function radialPath(p: Placed, angleOf: (y: number) => number, radiusOf: (x: number) => number) {
  if (!p.parent) return "";
  const a = angleOf(p.y);
  const [x0, y0] = polar(a, radiusOf(p.parent.x));
  const [x1, y1] = polar(a, radiusOf(p.x));
  return `M${x0.toFixed(1)} ${y0.toFixed(1)} L${x1.toFixed(1)} ${y1.toFixed(1)}`;
}

export function radialArc(p: Placed, angleOf: (y: number) => number, radiusOf: (x: number) => number) {
  if (!p.children.length) return "";
  const r = radiusOf(p.x);
  const a0 = angleOf(p.children[0].y);
  const a1 = angleOf(p.children[p.children.length - 1].y);
  const [x0, y0] = polar(a0, r);
  const [x1, y1] = polar(a1, r);
  const large = a1 - a0 > Math.PI ? 1 : 0;
  return `M${x0.toFixed(1)} ${y0.toFixed(1)} A${r.toFixed(1)} ${r.toFixed(1)} 0 ${large} 1 ${x1.toFixed(1)} ${y1.toFixed(1)}`;
}

/** Every node on the path from a tip to the root. */
export const ancestry = (tip: Placed | undefined) => {
  const out = new Set<Placed>();
  for (let p = tip; p; p = p.parent ?? undefined) out.add(p);
  return out;
};
