/**
 * The "Patterns" view: the whole dataset shown chart by chart, each in a
 * different form. Hover or focus updates a readout line under the chart
 * (never a floating tooltip, so nothing covers the marks and nothing has to
 * be dismissed), and every chart has a data table.
 */
import { useState } from "preact/hooks";
import { byId, cladeVar, data, DANGER, plateUrl, withBase, type Ghost } from "../utils/data";

const traits = data.characters.slice(0, 18).filter((c) => c.id !== "sex");
const pct = (n: number, d: number) => (d ? Math.round((n / d) * 100) : 0);
const plural = (n: number, one: string, many = `${one}s`) => `${n} ${n === 1 ? one : many}`;

function Readout({ text, idle }: { text: string | null; idle: string }) {
  return (
    <p class="muted mt-3 min-h-[2.5rem] rounded-2xl bg-kafan-100 px-4 py-2 text-sm dark:bg-malam-900" aria-live="polite">
      {text ?? idle}
    </p>
  );
}

function DataTable({ caption, head, rows }: { caption: string; head: string[]; rows: (string | number)[][] }) {
  return (
    <details class="mt-3">
      <summary class="accent cursor-pointer text-sm font-semibold underline underline-offset-2">Show the data as a table</summary>
      <div class="mt-2 max-h-96 overflow-auto rounded-2xl border border-kafan-300 dark:border-malam-700" tabIndex={0} role="region" aria-label={`${caption} (scrollable)`}>
        <table class="w-full text-left text-sm">
          <caption class="sr-only">{caption}</caption>
          <thead class="sticky top-0 bg-kafan-100 dark:bg-malam-900">
            <tr>{head.map((h) => <th key={h} scope="col" class="px-3 py-1.5 font-semibold">{h}</th>)}</tr>
          </thead>
          <tbody>
            {rows.map((r, i) => (
              <tr key={i} class="border-t border-kafan-200 dark:border-malam-800">
                {r.map((c, j) => (j === 0 ? <th key={j} scope="row" class="px-3 py-1 text-left font-semibold">{c}</th> : <td key={j} class="px-3 py-1 tabular-nums">{c}</td>))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </details>
  );
}

function Swatch({ color, label }: { color: string; label: string }) {
  return (
    <li class="inline-flex items-center gap-1.5">
      <span class="h-3 w-3 rounded-sm border border-malam-950/30 dark:border-white/30" style={{ background: color }} />
      {label}
    </li>
  );
}

/* ---- 1. Archipelago map --------------------------------------------------- */

const REGION_AT: Record<string, [number, number]> = {
  Sumatra: [101.2, -0.6],
  Java: [110.2, -7.3],
  Bali: [115.2, -8.4],
  "Nusa Tenggara": [120.6, -8.7],
  Kalimantan: [114, 0.6],
  Sulawesi: [120.6, -2.2],
  Maluku: [128.8, -3.2],
  Papua: [138, -4.6],
  Widespread: [100, -9.6],
  Outgroup: [126.5, 5.6],
};

export function ArchipelagoMap({ land, width, height }: { land: string; width: number; height: number }) {
  const [region, setRegion] = useState<string>("Java");
  const [hover, setHover] = useState<string | null>(null);
  const bbox = { west: 94, east: 142, south: -11.5, north: 7.5 };
  const px = (lon: number) => ((lon - bbox.west) / (bbox.east - bbox.west)) * width;
  const py = (lat: number) => ((bbox.north - lat) / (bbox.north - bbox.south)) * height;
  const groups = data.regions.map((r) => ({ region: r, ghosts: data.ghosts.filter((g) => g.regionGroup === r) }));
  const max = Math.max(...groups.map((g) => g.ghosts.length));
  const radius = (n: number) => 8 + Math.sqrt(n / max) * 34;
  const top = (gs: Ghost[]) => {
    const c = new Map<string, number>();
    gs.forEach((g) => c.set(g.clade, (c.get(g.clade) ?? 0) + 1));
    return [...c].sort((a, b) => b[1] - a[1]);
  };
  const describe = (r: string) => {
    const gs = groups.find((g) => g.region === r)!.ghosts;
    const [c, n] = top(gs)[0];
    return `${r}: ${plural(gs.length, "ghost")}; most are ${c} (${n}).`;
  };
  const shown = groups.find((g) => g.region === region)!.ghosts;

  return (
    <div>
      <svg viewBox={`0 0 ${width} ${height}`} class="h-auto w-full" role="group" aria-label="Map of the archipelago with one bubble per region, sized by number of ghosts">
        <path d={land} class="fill-kafan-300 stroke-kafan-500 dark:fill-malam-800 dark:stroke-malam-600" stroke-width={0.6} />
        {groups.map(({ region: r, ghosts: gs }) => {
          const [lon, lat] = REGION_AT[r];
          const x = px(lon);
          const y = py(lat);
          const rad = radius(gs.length);
          const on = r === region;
          const offMap = r === "Widespread" || r === "Outgroup";
          return (
            <g
              key={r}
              role="button"
              tabIndex={0}
              aria-pressed={on}
              aria-label={`${describe(r)} Show them.`}
              class="cursor-pointer"
              onClick={() => setRegion(r)}
              onKeyDown={(e) => (e.key === "Enter" || e.key === " ") && (e.preventDefault(), setRegion(r))}
              onMouseEnter={() => setHover(r)}
              onMouseLeave={() => setHover(null)}
              onFocus={() => setHover(r)}
              onBlur={() => setHover(null)}
            >
              {offMap && <rect x={x - 54} y={y - rad - 4} width={108} height={rad * 2 + 30} rx={14} class="fill-none stroke-kafan-700 dark:stroke-kemenyan-400" stroke-dasharray="4 4" />}
              <circle cx={x} cy={y} r={rad + 4} class={on || hover === r ? "fill-prada-300/60 dark:fill-prada-300/40" : "fill-transparent"} />
              <circle cx={x} cy={y} r={rad} class="fill-darah-700 stroke-kafan-50 dark:fill-darah-600 dark:stroke-malam-950" stroke-width={2} />
              <text x={x} y={y + 5} text-anchor="middle" class="pointer-events-none fill-white text-[15px] font-bold">{gs.length}</text>
              <text x={x} y={y + rad + 18} text-anchor="middle" class="pointer-events-none fill-malam-950 text-[13px] font-semibold dark:fill-kafan-100" paint-order="stroke" stroke-width={4} style={{ stroke: "var(--label-halo, #fbf8f1)" }}>
                {r === "Outgroup" ? "Outgroups" : r}
              </text>
            </g>
          );
        })}
      </svg>
      <Readout text={hover ? describe(hover) : null} idle="Bubble area is proportional to the number of ghosts. Select a region to list its ghosts." />
      <h3 class="mt-4 font-semibold">
        {region === "Outgroup" ? "Outgroups" : region} <span class="muted font-normal">· {plural(shown.length, "ghost")}</span>
      </h3>
      <ul class="mt-2 flex flex-wrap gap-2">
        {shown.map((g) => (
          <li key={g.id}>
            <a href={withBase(`/ghosts/${g.id}`)} class="control flex items-center gap-1.5 py-0.5 pl-0.5 pr-3 text-sm hover:bg-kafan-200 dark:hover:bg-malam-800">
              <img src={plateUrl(g.id)} alt="" width={26} height={26} class="rounded-full" />
              {g.name}
            </a>
          </li>
        ))}
      </ul>
      <DataTable
        caption="Ghosts per region and their most common clade"
        head={["Region", "Ghosts", "Most common clade"]}
        rows={groups.map(({ region: r, ghosts: gs }) => [r, gs.length, `${top(gs)[0][0]} (${top(gs)[0][1]})`])}
      />
    </div>
  );
}

/* ---- 2. Clade × trait heatmap -------------------------------------------- */

const SEQ = ["var(--seq-0)", "var(--seq-1)", "var(--seq-2)", "var(--seq-3)", "var(--seq-4)", "var(--seq-5)"];
const seqIndex = (p: number) => Math.min(5, Math.floor(p / 20) + (p === 0 ? 0 : 1));

export function TraitHeatmap() {
  const [hover, setHover] = useState<string | null>(null);
  const rows = [...data.clades.map((c) => ({ label: c, ghosts: data.ghosts.filter((g) => g.clade === c) })), { label: "All ghosts", ghosts: data.ghosts }];
  const CELL = 30;
  const LEFT = 210;
  const TOP = 118;
  const W = LEFT + traits.length * CELL + 4;
  const H = TOP + rows.length * CELL + 8;
  return (
    <div>
      <div class="overflow-x-auto" tabIndex={0} role="region" aria-label="Trait heatmap (scrolls sideways)">
        <svg viewBox={`0 0 ${W} ${H}`} class="h-auto w-full min-w-[640px]" role="img" aria-label="Heatmap of the share of each clade that has each trait. The table below lists every value.">
          {traits.map((t, j) => (
            <text key={t.id} transform={`translate(${LEFT + j * CELL + CELL / 2 + 4} ${TOP - 8}) rotate(-55)`} class="fill-malam-950 text-[12px] dark:fill-kafan-100">
              {t.label}
            </text>
          ))}
          {rows.map((r, i) => {
            const y = TOP + i * CELL;
            const last = i === rows.length - 1;
            return (
              <g key={r.label}>
                {!last && <circle cx={10} cy={y + CELL / 2} r={5} style={{ fill: cladeVar(r.label) }} />}
                <text x={last ? 4 : 20} y={y + CELL / 2 + 4} class={`fill-malam-950 text-[12.5px] dark:fill-kafan-100 ${last ? "font-bold" : ""}`}>
                  {r.label} ({r.ghosts.length})
                </text>
                {traits.map((t, j) => {
                  const n = r.ghosts.filter((g) => g.traits[t.id] === 1).length;
                  const p = pct(n, r.ghosts.length);
                  const msg = `${r.label}: ${p}% have ${t.label.toLowerCase()} (${n} of ${r.ghosts.length}).`;
                  return (
                    <rect
                      key={t.id}
                      x={LEFT + j * CELL + 1}
                      y={y + 1 + (last ? 4 : 0)}
                      width={CELL - 2}
                      height={CELL - 2}
                      rx={4}
                      style={{ fill: SEQ[seqIndex(p)] }}
                      class="stroke-malam-950/10 dark:stroke-white/10"
                      onMouseEnter={() => setHover(msg)}
                      onMouseLeave={() => setHover(null)}
                    />
                  );
                })}
              </g>
            );
          })}
        </svg>
      </div>
      <ul class="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs" aria-label="Colour scale">
        <li class="font-semibold">Share with the trait</li>
        {["0%", "1–20%", "21–40%", "41–60%", "61–80%", "81–100%"].map((l, i) => <Swatch key={l} color={SEQ[i]} label={l} />)}
      </ul>
      <Readout text={hover} idle="Darker cells mean more of the clade has the trait. Hover a cell for the exact share." />
      <DataTable
        caption="Percent of each clade with each trait"
        head={["Clade", ...traits.map((t) => t.label)]}
        rows={rows.map((r) => [r.label, ...traits.map((t) => `${pct(r.ghosts.filter((g) => g.traits[t.id] === 1).length, r.ghosts.length)}%`)])}
      />
    </div>
  );
}

/* ---- 3. Danger unit chart -------------------------------------------------- */

export function DangerUnits() {
  const [hover, setHover] = useState<Ghost | null>(null);
  return (
    <div>
      <div class="overflow-x-auto" tabIndex={0} role="region" aria-label="Danger chart (scrolls sideways)">
        <table class="w-full min-w-[640px] border-separate border-spacing-y-1 text-sm">
          <caption class="sr-only">Ghosts by clade and danger level; each plate is one ghost</caption>
          <thead>
            <tr>
              <th scope="col" class="w-44 text-left font-semibold">Clade</th>
              {[1, 2, 3, 4, 5].map((d) => (
                <th key={d} scope="col" class="px-1 text-left font-semibold">
                  {d} · {DANGER[d]}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {data.clades.map((c) => (
              <tr key={c}>
                <th scope="row" class="pr-2 text-left align-top font-normal">
                  <span class="inline-flex items-start gap-1.5">
                    <span class="mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: cladeVar(c) }} />
                    {c}
                  </span>
                </th>
                {[1, 2, 3, 4, 5].map((d) => {
                  const gs = data.ghosts.filter((g) => g.clade === c && g.danger === d);
                  return (
                    <td key={d} class="rounded-xl bg-kafan-100/80 p-1 align-top dark:bg-malam-900/80">
                      <ul class="flex flex-wrap gap-0.5" aria-label={`${c}, ${DANGER[d]}: ${gs.length ? gs.map((g) => g.name).join(", ") : "none"}`}>
                        {gs.map((g) => (
                          <li key={g.id} onMouseEnter={() => setHover(g)} onMouseLeave={() => setHover(null)}>
                            <img src={plateUrl(g.id)} alt="" width={22} height={22} class="rounded-full" />
                          </li>
                        ))}
                      </ul>
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Readout text={hover ? `${hover.name}: ${hover.clade}, danger ${hover.danger} (${DANGER[hover.danger].toLowerCase()}).` : null} idle="Each plate is one ghost. Hover a plate for its name; screen readers hear the names cell by cell." />
    </div>
  );
}

/* ---- 4. Body plan × diet bubble matrix ------------------------------------- */

export function BodyDiet() {
  const [hover, setHover] = useState<string | null>(null);
  const diets = [...data.characters[19].states, "Unknown"];
  const plans = data.bodyPlans.filter((b) => data.ghosts.some((g) => g.bodyPlan === b.id));
  const count = (plan: string, diet: string) =>
    data.ghosts.filter((g) => g.bodyPlan === plan && (g.dietClass ?? "Unknown") === diet);
  const max = Math.max(...plans.flatMap((p) => diets.map((d) => count(p.id, d).length)));
  const CELL = 56;
  const ROW = 30;
  const LEFT = 200;
  const TOP = 64;
  const W = LEFT + diets.length * CELL;
  const H = TOP + plans.length * ROW + 6;
  return (
    <div>
      <div class="overflow-x-auto" tabIndex={0} role="region" aria-label="Body plan and diet chart (scrolls sideways)">
        <svg viewBox={`0 0 ${W} ${H}`} class="h-auto w-full min-w-[560px]" role="img" aria-label="Bubble matrix of body plan against diet; bubble area is the number of ghosts. The table below lists every count.">
          {diets.map((d, j) => (
            <text key={d} transform={`translate(${LEFT + j * CELL + CELL / 2} ${TOP - 10}) rotate(-25)`} class="fill-malam-950 text-[12px] dark:fill-kafan-100">
              {d}
            </text>
          ))}
          {plans.map((p, i) => {
            const y = TOP + i * ROW + ROW / 2;
            return (
              <g key={p.id}>
                <line x1={LEFT} x2={W} y1={y} y2={y} class="stroke-kafan-300 dark:stroke-malam-800" />
                <text x={LEFT - 10} y={y + 4} text-anchor="end" class="fill-malam-950 text-[12.5px] dark:fill-kafan-100">{p.label}</text>
                {diets.map((d, j) => {
                  const gs = count(p.id, d);
                  if (!gs.length) return null;
                  const r = 3 + Math.sqrt(gs.length / max) * 12;
                  return (
                    <circle
                      key={d}
                      cx={LEFT + j * CELL + CELL / 2}
                      cy={y}
                      r={r}
                      class="fill-malam-700 stroke-kafan-50 dark:fill-prada-300 dark:stroke-malam-950"
                      stroke-width={2}
                      onMouseEnter={() => setHover(`${p.label}, ${d.toLowerCase()}: ${gs.map((g) => g.name).join(", ")}.`)}
                      onMouseLeave={() => setHover(null)}
                    />
                  );
                })}
              </g>
            );
          })}
        </svg>
      </div>
      <Readout text={hover} idle="Bubble area is the number of ghosts with that body plan and diet. Hover a bubble to list them." />
      <DataTable
        caption="Ghosts by body plan and diet"
        head={["Body plan", ...diets]}
        rows={plans.map((p) => [p.label, ...diets.map((d) => count(p.id, d).length)])}
      />
    </div>
  );
}

/* ---- 5. Coding provenance bars --------------------------------------------- */

const CODING = [
  { key: "source", label: "Source matrix", color: "var(--seq-5)" },
  { key: "filled", label: "Gaps filled by synthesis", color: "var(--seq-2)" },
  { key: "new", label: "New entry by synthesis", color: "var(--seq-1)" },
] as const;

export function Provenance() {
  const [hover, setHover] = useState<string | null>(null);
  const max = Math.max(...data.clades.map((c) => data.ghosts.filter((g) => g.clade === c).length));
  return (
    <div>
      <ul class="flex flex-wrap gap-x-4 gap-y-1 text-xs" aria-label="Legend">
        {CODING.map((c) => <Swatch key={c.key} color={c.color} label={c.label} />)}
      </ul>
      <ul class="mt-3 space-y-1.5">
        {data.clades.map((c) => {
          const gs = data.ghosts.filter((g) => g.clade === c);
          return (
            <li key={c} class="grid grid-cols-[minmax(0,11rem)_1fr] items-center gap-3 text-sm">
              <span class="inline-flex items-center gap-1.5">
                <span class="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: cladeVar(c) }} />
                {c}
              </span>
              <span class="flex h-6 gap-0.5" style={{ width: `${(gs.length / max) * 100}%` }} aria-label={`${c}: ${CODING.map((k) => `${gs.filter((g) => g.coding === k.key).length} ${k.label.toLowerCase()}`).join(", ")}`} role="img">
                {CODING.map((k) => {
                  const n = gs.filter((g) => g.coding === k.key).length;
                  if (!n) return null;
                  return (
                    <span
                      key={k.key}
                      class="flex items-center justify-center rounded-[4px] text-[11px] font-bold first:rounded-l-md last:rounded-r-md"
                      style={{ flex: n, background: k.color, color: k.key === "source" ? "var(--seq-0)" : "var(--seq-5)" }}
                      onMouseEnter={() => setHover(`${c}: ${n} of ${gs.length} — ${k.label.toLowerCase()}.`)}
                      onMouseLeave={() => setHover(null)}
                    >
                      {n}
                    </span>
                  );
                })}
              </span>
            </li>
          );
        })}
      </ul>
      <Readout text={hover} idle="Bar length is the clade size; segments show where each ghost's coding comes from." />
    </div>
  );
}

/* ---- 6. Support histogram --------------------------------------------------- */

export function SupportHistogram({ supports }: { supports: number[] }) {
  const [hover, setHover] = useState<string | null>(null);
  const bins = Array.from({ length: 10 }, (_, i) => ({ from: i * 10, to: i * 10 + 9, n: 0 }));
  supports.forEach((s) => bins[Math.min(9, Math.floor(s / 10))].n++);
  bins[9].to = 100;
  const max = Math.max(...bins.map((b) => b.n));
  const W = 640;
  const H = 220;
  const B = 30;
  const plotH = H - B - 16;
  const bw = (W - 40) / 10;
  return (
    <div>
      <svg viewBox={`0 0 ${W} ${H}`} class="h-auto w-full" role="img" aria-label={`Histogram of ultrafast bootstrap support across ${supports.length} nodes. The table below lists the counts.`}>
        {[0, Math.ceil(max / 2), max].map((t) => {
          const y = 8 + plotH - (t / max) * plotH;
          return (
            <g key={t}>
              <line x1={36} x2={W} y1={y} y2={y} class="stroke-kafan-300 dark:stroke-malam-800" />
              <text x={30} y={y + 4} text-anchor="end" class="fill-malam-950 text-[11px] dark:fill-kafan-100">{t}</text>
            </g>
          );
        })}
        {bins.map((b, i) => {
          const h = (b.n / max) * plotH;
          const x = 40 + i * bw;
          return (
            <g key={i} onMouseEnter={() => setHover(`${plural(b.n, "node")} with support ${b.from}–${b.to}.`)} onMouseLeave={() => setHover(null)}>
              <rect x={x} y={8} width={bw} height={plotH} class="fill-transparent" />
              <path d={`M${x + 2} ${8 + plotH} V${8 + plotH - h + 4} q0 -4 4 -4 H${x + bw - 6} q4 0 4 4 V${8 + plotH} Z`} class={b.from >= 90 ? "fill-darah-700 dark:fill-prada-300" : "fill-malam-600 dark:fill-kemenyan-400"} />
              <text x={x + bw / 2} y={H - 10} text-anchor="middle" class="fill-malam-950 text-[11px] dark:fill-kafan-100">{b.from}</text>
            </g>
          );
        })}
      </svg>
      <Readout text={hover} idle="Most nodes have low support, so the deep branching is unresolved. Bars at 90 and above are highlighted." />
      <DataTable caption="Nodes by support bin" head={["Support", "Nodes"]} rows={bins.map((b) => [`${b.from}–${b.to}`, b.n])} />
    </div>
  );
}

/* ---- 7. Twins ---------------------------------------------------------------- */

export function Twins() {
  const seen = new Set<string>();
  const sets: Ghost[][] = [];
  for (const g of data.ghosts) {
    if (!g.twins.length || seen.has(g.id)) continue;
    const set = [g, ...g.twins.map((t) => byId.get(t)!)];
    set.forEach((s) => seen.add(s.id));
    sets.push(set);
  }
  return (
    <ul class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
      {sets.map((set, i) => (
        <li key={i} class="rounded-2xl border border-kafan-300 bg-kafan-100/70 p-3 dark:border-malam-700 dark:bg-malam-900/70">
          <div class="flex flex-wrap gap-1">
            {set.map((g) => (
              <img key={g.id} src={plateUrl(g.id)} alt="" width={36} height={36} class="rounded-full" />
            ))}
          </div>
          <p class="mt-2 text-sm">
            {set.map((g, j) => (
              <span key={g.id}>
                {j > 0 && (j === set.length - 1 ? " and " : ", ")}
                <a href={withBase(`/ghosts/${g.id}`)} class="font-semibold underline decoration-kafan-500 underline-offset-2 hover:decoration-darah-600">{g.name}</a>
              </span>
            ))}
          </p>
        </li>
      ))}
    </ul>
  );
}
