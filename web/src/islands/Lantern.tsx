/**
 * Design B, "Lantern": a circular tree on a night canvas, the selected ghost
 * held in the centre like a lamp. Hovering a tip lights its path to the root;
 * island chips dim everything else. The canvas forces the dark palette (the
 * `dark` class) so it reads the same in either site theme.
 */
import { useMemo, useState } from "preact/hooks";
import { byId, cladeVar, data, plateUrl } from "../utils/data";
import { ancestry, layout, polar, radialArc, radialPath } from "../utils/tree";
import GhostCard from "./GhostCard";

const HALF = 560;
const INNER = 120;
const OUTER = 330;
const GAP = 0.22; // radians left open at the top for the title
// Space between the label start and the clade ring, in SVG units.
const LABEL_ROOM = 150;

export default function Lantern() {
  const [selected, setSelected] = useState(data.ghosts[0].id);
  const [hover, setHover] = useState<string | null>(null);
  const [region, setRegion] = useState<string>("");

  const L = useMemo(() => layout(data.tree, (id) => byId.get(id)!.clade, "cladogram"), []);
  const angleOf = (y: number) => -Math.PI / 2 + GAP / 2 + (y / (L.nTips - 1)) * (2 * Math.PI - GAP);
  const radiusOf = (x: number) => INNER + (x / L.maxX) * (OUTER - INNER);
  const tipById = new Map(L.tips.map((t) => [t.id!, t]));
  const lit = ancestry(tipById.get(hover ?? selected));
  const ghost = byId.get(selected)!;
  const focus = byId.get(hover ?? selected)!;

  // Contiguous runs of one clade around the rim, drawn as an outer ring.
  const runs: { clade: string; from: number; to: number }[] = [];
  for (const t of L.tips) {
    const c = byId.get(t.id!)!.clade;
    const last = runs[runs.length - 1];
    if (last && last.clade === c && last.to === t.y - 1) last.to = t.y;
    else runs.push({ clade: c, from: t.y, to: t.y });
  }
  const ringR = 522;
  const arc = (from: number, to: number) => {
    const a0 = angleOf(from - 0.45);
    const a1 = angleOf(to + 0.45);
    const [x0, y0] = polar(a0, ringR);
    const [x1, y1] = polar(a1, ringR);
    return `M${x0} ${y0} A${ringR} ${ringR} 0 ${a1 - a0 > Math.PI ? 1 : 0} 1 ${x1} ${y1}`;
  };

  const counts = new Map<string, number>();
  data.ghosts.forEach((g) => counts.set(g.regionGroup, (counts.get(g.regionGroup) ?? 0) + 1));

  return (
    <div class="mx-auto max-w-7xl">
      <p class="sr-only" aria-live="polite">Showing the card for {ghost.name}.</p>
      <div class="glass mx-auto mb-4 flex max-w-5xl flex-wrap justify-center gap-2 px-3 py-3" role="group" aria-label="Filter by island">
        {["", ...data.regions].map((r) => (
          <button
            key={r || "all"}
            type="button"
            aria-pressed={region === r}
            onClick={() => setRegion(r)}
            class={`rounded-full border px-3 py-1 text-sm transition ${
              region === r
                ? "border-malam-900 bg-malam-900 text-prada-200 dark:border-prada-300 dark:bg-prada-300 dark:text-malam-950"
                : "border-kafan-700 hover:bg-kafan-200 dark:border-kemenyan-400 dark:hover:bg-malam-800"
            }`}
          >
            {r || "All islands"}
            {r && <span class="ml-1">{counts.get(r) ?? 0}</span>}
          </button>
        ))}
      </div>

      <div class="grid items-start gap-6 lg:grid-cols-[minmax(0,1fr)_24rem]">
        {/* The night canvas: `dark` on a wrapper so dark variants and clade colours apply inside. */}
        <div class="dark min-w-0">
        <figure class="glass relative overflow-hidden !rounded-[2.5rem] !bg-malam-950/[0.85] p-2 text-kafan-100">
          <div aria-hidden="true" class="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(217,171,60,0.20),transparent_45%)]" />
          <svg
            viewBox={`${-HALF} ${-HALF} ${HALF * 2} ${HALF * 2}`}
            class="relative block h-auto w-full"
            role="group"
            aria-label={`Circular tree of ${L.nTips} ghosts. ${ghost.name} is in the centre.`}
          >
            {/* Stars */}
            {Array.from({ length: 70 }, (_, i) => {
              const a = (i * 137.5 * Math.PI) / 180;
              const r = 360 + ((i * 53) % 190);
              const [x, y] = polar(a, r);
              return <circle key={i} cx={x} cy={y} r={0.8 + (i % 3) * 0.5} class="fill-kafan-100" opacity={0.15 + (i % 5) * 0.08} />;
            })}

            {/* Clade ring */}
            {runs.map((r, i) => (
              <path key={i} d={arc(r.from, r.to)} fill="none" stroke={cladeVar(r.clade)} stroke-width={10} stroke-linecap="butt" opacity={0.9}>
                <title>{r.clade}</title>
              </path>
            ))}

            {/* Branches */}
            <g fill="none" stroke-linecap="round">
              {L.all.map((p, i) => {
                const on = lit.has(p);
                const color = p.clade ? cladeVar(p.clade) : "var(--neutral-branch)";
                return (
                  <g key={i} opacity={on ? 1 : 0.75}>
                    <path d={radialPath(p, angleOf, radiusOf)} stroke={on ? "#f4dc8e" : color} stroke-width={on ? 3.6 : 1.5} />
                    <path d={radialArc(p, angleOf, radiusOf)} stroke={color} stroke-width={1.5} />
                  </g>
                );
              })}
              {/* Glow on the lit path */}
              {[...lit].map((p, i) => (
                <path key={`g${i}`} d={radialPath(p, angleOf, radiusOf)} stroke="#e0b03e" stroke-width={10} opacity={0.15} />
              ))}
            </g>

            {/* Strong nodes */}
            {L.all
              .filter((p) => p.children.length && (p.support ?? 0) >= 95)
              .map((p, i) => {
                const [x, y] = polar(angleOf(p.y), radiusOf(p.x));
                return (
                  <circle key={i} cx={x} cy={y} r={3.6} class="fill-prada-300">
                    <title>UFBoot {p.support}</title>
                  </circle>
                );
              })}

            {/* Tips */}
            {L.tips.map((t) => {
              const g = byId.get(t.id!)!;
              const a = angleOf(t.y);
              const deg = (a * 180) / Math.PI;
              const flip = Math.cos(a) < 0;
              const [px, py] = polar(a, OUTER + 13);
              const [lx, ly] = polar(a, OUTER + 26);
              const dim = region && g.regionGroup !== region;
              const isSel = t.id === selected;
              return (
                <g
                  key={t.id}
                  class="cursor-pointer"
                  onMouseEnter={() => setHover(t.id!)}
                  onMouseLeave={() => setHover(null)}
                  onClick={() => setSelected(t.id!)}
                  role="button"
                  tabIndex={0}
                  aria-label={`${g.name}, ${g.clade}, ${g.region}`}
                  onFocus={() => setHover(t.id!)}
                  onBlur={() => setHover(null)}
                  onKeyDown={(e) => (e.key === "Enter" || e.key === " ") && (e.preventDefault(), setSelected(t.id!))}
                >
                  {isSel && <circle cx={px} cy={py} r={13} class="fill-prada-300" opacity={0.45} />}
                  {t.id === hover && <circle cx={px} cy={py} r={13} fill="none" class="stroke-prada-200" stroke-width={2} />}
                  <image href={plateUrl(g.id)} x={px - 9} y={py - 9} width={18} height={18} opacity={dim ? 0.25 : 1} />
                  <text
                    transform={`translate(${lx} ${ly}) rotate(${flip ? deg + 180 : deg})`}
                    text-anchor={flip ? "end" : "start"}
                    dominant-baseline="middle"
                    style={{ fontSize: `${Math.min(12.5, LABEL_ROOM / (g.name.length * 0.56))}px` }}
                    class={isSel || t.id === hover ? "fill-prada-200 font-bold" : dim ? "fill-kemenyan-300" : region ? "fill-kafan-50 font-bold" : "fill-kafan-200"}
                  >
                    {g.name}
                  </text>
                </g>
              );
            })}

            {/* The lantern: focused ghost in the centre */}
            <circle r={INNER - 14} class="fill-malam-950" stroke="#e0b03e" stroke-opacity={0.5} stroke-width={1.5} />
            <image href={plateUrl(focus.id)} x={-62} y={-98} width={124} height={124} class="animate-flicker" />
            <text y={50} text-anchor="middle" class="fill-prada-200 font-serif font-semibold" style={{ fontSize: `${Math.min(19, 180 / (focus.name.length * 0.5))}px` }}>
              {focus.name}
            </text>
            <text y={70} text-anchor="middle" class="fill-kemenyan-200 text-[11.5px]">
              {focus.regionGroup === "Outgroup" ? "Outgroup" : focus.regionGroup}
            </text>
            <text y={86} text-anchor="middle" class="fill-kemenyan-200 text-[11.5px]">
              {focus.clade}
            </text>
          </svg>
          <figcaption class="relative px-4 pb-4 text-center text-sm text-kemenyan-200">
            Hover or focus a ghost to light its lineage; select it to read its card. Gold dots mark ultrafast bootstrap ≥ 95. The outer ring shows clades; the legend above names them.
          </figcaption>
        </figure>
        </div>

        <aside class="lg:sticky lg:top-24" aria-label="Selected ghost">
          <GhostCard ghost={ghost} onSelect={setSelected} />
        </aside>
      </div>
    </div>
  );
}
