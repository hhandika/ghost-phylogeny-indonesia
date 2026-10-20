/**
 * The "Patterns" view: the whole dataset shown chart by chart, each in a
 * different form. Hover or focus updates a readout line under the chart
 * (never a floating tooltip, so nothing covers the marks and nothing has to
 * be dismissed), and every chart has a data table.
 */
import { useState } from "preact/hooks";
import { byId, cladeVar, data, plateUrl, type Ghost } from "../utils/data";
import { dangerLabel, localePath, regionName, tr, useT, type Key, type Lang } from "../i18n";

const traits = data.characters.slice(0, 18).filter((c) => c.id !== "sex");
const pct = (n: number, d: number) => (d ? Math.round((n / d) * 100) : 0);

function Readout({ text, idle }: { text: string | null; idle: string }) {
  return (
    <p class="muted mt-3 min-h-[2.5rem] rounded-2xl bg-kafan-100 px-4 py-2 text-sm dark:bg-malam-900" aria-live="polite">
      {text ?? idle}
    </p>
  );
}

function DataTable({ lang, caption, head, rows }: { lang: Lang; caption: string; head: string[]; rows: (string | number)[][] }) {
  const t = useT(lang);
  return (
    <details class="mt-3">
      <summary class="accent cursor-pointer text-sm font-semibold underline underline-offset-2">{t("showTable")}</summary>
      <div class="mt-2 max-h-96 overflow-auto rounded-2xl border border-kafan-300 dark:border-malam-700" tabIndex={0} role="region" aria-label={t("scrollable", caption)}>
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

/* ---- 1. Archipelago map with Pleistocene sea levels ----------------------- */

/** Map frame: equirectangular, 20 SVG units per degree. Shared with patterns.astro. */
export const MAP_BBOX = { west: 94, east: 142, south: -12.5, north: 7.5 };
export const MAP_SCALE = 20;
const mx = (lon: number) => (lon - MAP_BBOX.west) * MAP_SCALE;
const my = (lat: number) => (MAP_BBOX.north - lat) * MAP_SCALE;
const linePath = (pts: number[][]) => "M" + pts.map(([lon, lat]) => `${mx(lon).toFixed(1)} ${my(lat).toFixed(1)}`).join("L");
// The shelf paths come in the frame of hhandika-com's IAA map
// (x = 33 + 11.647 (lon − 95.2), y = 175.3 + 11.6 (5.65 − lat)); this matrix
// maps that frame onto ours.
const SHELF_MATRIX = (() => {
  const a = MAP_SCALE / 11.647;
  const d = MAP_SCALE / 11.6;
  return `matrix(${a} 0 0 ${d} ${mx(95.2) - 33 * a} ${my(5.65) - 175.3 * d})`;
})();

const LEVELS: { level: number; label: Key | string; note: Key }[] = [
  { level: 0, label: "today", note: "lvlToday" },
  { level: -40, label: "−40 m", note: "lvl40" },
  { level: -80, label: "−80 m", note: "lvl80" },
  { level: -120, label: "−120 m", note: "lvl120" },
];

// Approximate placements after Wallace (1863), Huxley (1868), Weber (1902),
// and Lydekker (1896), as on hhandika-com's speciation map.
const LINES = [
  { id: "wallace", name: "lineWallace" as Key, color: "#e67e14", note: "between Bali and Lombok, Borneo and Sulawesi", points: [[115.8, -10.5], [115.75, -8.7], [116.4, -6.8], [117.25, -5.2], [117.8, -3.8], [118.35, -2.5], [118.4, -1.0], [118.7, 0.2], [119.45, 1.1], [119.5, 2.2], [119.6, 3.2], [121.5, 4.6], [124.0, 5.3], [126.2, 5.4], [127.3, 5.9], [128.8, 6.6]] },
  { id: "huxley", name: "lineHuxley" as Key, color: "#e2b93b", note: "like Wallace's, but placing most of the Philippines east of the line", points: [[119.5, 2.2], [119.5, 4.2], [119.6, 5.0], [119.4, 6.0], [119.0, 7.3], [119.0, 8.6]] },
  { id: "weber", name: "lineWeber" as Key, color: "#c96fd8", note: "the line of faunal balance between Asian and Australian animals", points: [[129.2, 5.8], [127.8, 4.0], [127.1, 2.5], [126.9, 0.5], [126.9, -0.6], [126.8, -1.8], [126.3, -2.8], [125.75, -3.3], [125.8, -4.1], [126.6, -4.3], [127.7, -4.3], [128.8, -5.2], [129.6, -6.3], [129.5, -7.4], [129.2, -8.6], [128.0, -9.2], [126.5, -10.2], [124.8, -11.2]] },
  { id: "lydekker", name: "lineLydekker" as Key, color: "#5f92cb", note: "the western edge of the Sahul Shelf", points: [[125.5, -11.6], [127.0, -10.4], [129.6, -9.2], [131.6, -8.7], [132.2, -7.5], [133.3, -6.6], [133.7, -5.9], [133.65, -5.1], [132.2, -4.8], [131.4, -3.6], [129.6, -2.3], [129.3, -0.8], [129.5, 0.6], [130.5, 1.0], [131.8, 1.4]] },
];

// Bubble anchors. Widespread motifs and outgroups sit in open sea.
const REGION_AT: Record<string, [number, number]> = {
  Sumatra: [101.2, -0.6],
  Java: [110.2, -7.3],
  Bali: [115.2, -8.4],
  "Nusa Tenggara": [120.6, -8.7],
  Kalimantan: [114, 0.6],
  Sulawesi: [120.6, -2.2],
  Maluku: [128.8, -3.2],
  Papua: [138, -4.6],
  Widespread: [98.4, -8.6],
  Outgroup: [137, 3.6],
};
// Biogeographic regions, labelled once their shelves can be exposed.
const ZONES = [
  { name: "zoneSunda" as Key, lon: 106.5, lat: 4.2 },
  { name: "zoneWallacea" as Key, lon: 124.6, lat: -6.4 },
  { name: "zoneSahul" as Key, lon: 136.2, lat: -10.2 },
];

export function ArchipelagoMap({ lang, land, shelves }: { lang: Lang; land: string; shelves: { level: number; d: string }[] }) {
  const t = useT(lang);
  const lvLabel = (l: { label: string }) => (l.label === "today" ? t("today") : l.label);
  const [region, setRegion] = useState<string>("Java");
  const [hover, setHover] = useState<string | null>(null);
  const [level, setLevel] = useState(0);
  const [lines, setLines] = useState<Set<string>>(new Set(LINES.map((l) => l.id)));
  const [playing, setPlaying] = useState(false);
  const W = (MAP_BBOX.east - MAP_BBOX.west) * MAP_SCALE;
  const H = (MAP_BBOX.north - MAP_BBOX.south) * MAP_SCALE;

  const groups = data.regions.map((r) => ({ region: r, ghosts: data.ghosts.filter((g) => g.regionGroup === r) }));
  const max = Math.max(...groups.map((g) => g.ghosts.length));
  const radius = (n: number) => 8 + Math.sqrt(n / max) * 32;
  const top = (gs: Ghost[]) => {
    const c = new Map<string, number>();
    gs.forEach((g) => c.set(g.clade, (c.get(g.clade) ?? 0) + 1));
    return [...c].sort((a, b) => b[1] - a[1]);
  };
  const describe = (r: string) => {
    const gs = groups.find((g) => g.region === r)!.ghosts;
    const [c, n] = top(gs)[0];
    return t("regionSays", regionName(lang, r), gs.length, tr(lang, c), n);
  };
  const shown = groups.find((g) => g.region === region)!.ghosts;
  const lv = LEVELS.find((l) => l.level === level)!;

  // Step from today down to the Last Glacial Maximum.
  const play = () => {
    if (playing) return;
    setPlaying(true);
    const seq = LEVELS.map((l) => l.level);
    seq.forEach((l, i) => setTimeout(() => {
      setLevel(l);
      if (i === seq.length - 1) setPlaying(false);
    }, i * 1100));
  };
  const toggleLine = (id: string) =>
    setLines((s) => {
      const n = new Set(s);
      n.has(id) ? n.delete(id) : n.add(id);
      return n;
    });

  const btn = (on: boolean) =>
    `rounded-full px-3 py-1 text-sm font-semibold transition ${on ? "bg-malam-900 text-prada-200 dark:bg-prada-300 dark:text-malam-950" : "hover:bg-kafan-200 dark:hover:bg-malam-800"}`;

  const placed = groups.map(({ region: r, ghosts: gs }) => {
    const [lon, lat] = REGION_AT[r];
    return { r, gs, x: mx(lon), y: my(lat), rad: radius(gs.length) };
  });

  return (
    <div>
      <div class="flex flex-wrap items-center gap-x-4 gap-y-2">
        <div class="control flex flex-wrap items-center gap-0.5 p-1" role="group" aria-label={t("seaLevel")}>
          {LEVELS.map((l) => (
            <button key={l.level} type="button" aria-pressed={level === l.level} onClick={() => setLevel(l.level)} class={btn(level === l.level)}>
              {lvLabel(l)}
            </button>
          ))}
          <button type="button" onClick={play} disabled={playing} class={`${btn(false)} inline-flex items-center gap-1 disabled:opacity-60`} aria-label={t("animateSea")}>
            <svg viewBox="0 0 16 16" class="h-3.5 w-3.5" aria-hidden="true"><path d="M4 2.5v11l9-5.5z" fill="currentColor" /></svg>
            {t("play")}
          </button>
        </div>
        <div class="flex flex-wrap items-center gap-1.5" role="group" aria-label={t("bioLines")}>
          {LINES.map((l) => {
            const on = lines.has(l.id);
            return (
              <button
                key={l.id}
                type="button"
                aria-pressed={on}
                onClick={() => toggleLine(l.id)}
                class={`control inline-flex items-center gap-1.5 px-3 py-1 text-sm transition ${on ? "" : "line-through opacity-70"}`}
              >
                <svg width="18" height="6" aria-hidden="true"><line x1="1" y1="3" x2="17" y2="3" stroke="#1c1830" stroke-width="4.4" stroke-dasharray="5 3" /><line x1="1" y1="3" x2="17" y2="3" stroke={l.color} stroke-width="2.2" stroke-dasharray="5 3" /></svg>
                {t(l.name)}
              </button>
            );
          })}
        </div>
      </div>

      <div class="mt-3 overflow-x-auto rounded-2xl" tabIndex={0} role="region" aria-label={t("mapRegion")}>
        <svg viewBox={`0 0 ${W} ${H}`} class="block h-auto w-full min-w-[600px]" role="group" aria-label={t("mapSvg", lvLabel(lv), t(lv.note))}>
          <rect width={W} height={H} class="fill-[#dfe3ec] dark:fill-[#141022]" />
          {/* Exposed shelves (ETOPO1), drawn under today's land */}
          <g transform={SHELF_MATRIX}>
            {shelves.map((s) => (
              <path
                key={s.level}
                d={s.d}
                fill-rule="evenodd"
                class="fill-[#c4d6bd] stroke-[#4f7a4a] transition-opacity duration-700 motion-reduce:transition-none dark:fill-[#22382c] dark:stroke-[#7fb08a]"
                stroke-width={0.8}
                opacity={s.level === level ? 1 : 0}
              />
            ))}
          </g>
          <path d={land} class="fill-[#d6c7a6] stroke-[#8a7253] dark:fill-[#3a3358] dark:stroke-[#7d73a6]" stroke-width={0.7} />

          {/* Biogeographic lines, with a dark casing for 3:1 against land and sea */}
          <g fill="none" stroke-linecap="round" stroke-linejoin="round">
            {LINES.filter((l) => lines.has(l.id)).map((l) => (
              <g key={l.id}>
                <path d={linePath(l.points)} stroke="#1c1830" stroke-width={4.6} stroke-dasharray="8 5" />
                <path d={linePath(l.points)} stroke={l.color} stroke-width={2.2} stroke-dasharray="8 5" />
              </g>
            ))}
          </g>

          {/* Zone names appear once the sea has fallen */}
          <g text-anchor="middle" aria-hidden="true" class="transition-opacity duration-700 motion-reduce:transition-none" opacity={level <= -80 ? 1 : 0}>
            {ZONES.map((z) => (
              <text key={z.name} x={mx(z.lon)} y={my(z.lat)} class="fill-malam-900 text-[18px] font-bold uppercase tracking-[0.14em] dark:fill-kafan-100" paint-order="stroke" stroke-width={6} stroke-linejoin="round" style={{ stroke: "var(--label-halo)" }}>
                {t(z.name)}
              </text>
            ))}
          </g>

          {/* Bubbles first, then every label above them so nothing is covered */}
          {placed.map(({ r, x, y, rad }) => {
            const offMap = r === "Widespread" || r === "Outgroup";
            return offMap ? (
              <rect key={`box-${r}`} x={x - 64} y={y - rad - 10} width={128} height={rad * 2 + 42} rx={14} class="fill-none stroke-kafan-800 dark:stroke-kemenyan-300" stroke-dasharray="4 4" />
            ) : null;
          })}
          {placed.map(({ r, gs, x, y, rad }) => {
            const on = r === region;
            return (
              <g
                key={r}
                role="button"
                tabIndex={0}
                aria-pressed={on}
                aria-label={`${describe(r)} ${t("showThem")}`}
                class="cursor-pointer"
                onClick={() => setRegion(r)}
                onKeyDown={(e) => (e.key === "Enter" || e.key === " ") && (e.preventDefault(), setRegion(r))}
                onMouseEnter={() => setHover(r)}
                onMouseLeave={() => setHover(null)}
                onFocus={() => setHover(r)}
                onBlur={() => setHover(null)}
              >
                <circle cx={x} cy={y} r={rad + 5} class={on || hover === r ? "fill-none stroke-malam-950 dark:stroke-prada-200" : "fill-none stroke-transparent"} stroke-width={3} />
                <circle cx={x} cy={y} r={rad} class="fill-darah-700 stroke-kafan-50 dark:fill-darah-600 dark:stroke-malam-950" stroke-width={2} />
                <text x={x} y={y + 6} text-anchor="middle" class="pointer-events-none fill-white text-[17px] font-bold">{gs.length}</text>
              </g>
            );
          })}
          <g aria-hidden="true" text-anchor="middle" class="pointer-events-none">
            {placed.map(({ r, x, y, rad }) => (
              <text key={r} x={x} y={y + rad + 20} class="fill-malam-950 text-[17px] font-semibold dark:fill-kafan-100" paint-order="stroke" stroke-width={6} stroke-linejoin="round" style={{ stroke: "var(--label-halo)" }}>
                {regionName(lang, r)}
              </text>
            ))}
          </g>
        </svg>
      </div>
      <p class="muted mt-2 rounded-2xl bg-kafan-100 px-4 py-2 text-sm dark:bg-malam-900" role="status">
        {t("seaStatus", level === 0 ? t("seaToday") : lv.label, t(lv.note))}
        {level <= -80 && t("seaLowNote")}
      </p>
      <Readout text={hover ? describe(hover) : null} idle={t("mapIdle")} />
      <h3 class="mt-4 font-semibold">
        {regionName(lang, region)} <span class="muted font-normal">· {t("ghosts", shown.length)}</span>
      </h3>
      <ul class="mt-2 flex flex-wrap gap-2">
        {shown.map((g) => (
          <li key={g.id}>
            <a href={localePath(lang, `/ghosts/${g.id}`)} class="control flex items-center gap-1.5 py-0.5 pl-0.5 pr-3 text-sm hover:bg-kafan-200 dark:hover:bg-malam-800">
              <img src={plateUrl(g.id)} alt="" width={26} height={26} class="rounded-full" />
              {g.name}
            </a>
          </li>
        ))}
      </ul>
      <DataTable
        lang={lang}
        caption={t("regionTableCap")}
        head={[t("region"), t("ghostsWord"), t("mostCommonClade")]}
        rows={groups.map(({ region: r, ghosts: gs }) => [regionName(lang, r), gs.length, `${tr(lang, top(gs)[0][0])} (${top(gs)[0][1]})`])}
      />
    </div>
  );
}

/* ---- 2. Clade × trait heatmap -------------------------------------------- */

const SEQ = ["var(--seq-0)", "var(--seq-1)", "var(--seq-2)", "var(--seq-3)", "var(--seq-4)", "var(--seq-5)"];
const seqIndex = (p: number) => Math.min(5, Math.floor(p / 20) + (p === 0 ? 0 : 1));

export function TraitHeatmap({ lang }: { lang: Lang }) {
  const t = useT(lang);
  const [hover, setHover] = useState<string | null>(null);
  const rows = [...data.clades.map((c) => ({ key: c, label: tr(lang, c), ghosts: data.ghosts.filter((g) => g.clade === c) })), { key: "", label: t("allGhosts"), ghosts: data.ghosts }];
  const LEFT = Math.max(210, 30 + Math.max(...rows.map((r) => `${r.label} (${r.ghosts.length})`.length)) * 7);
  const TOP = Math.max(118, 20 + Math.max(...traits.map((x) => tr(lang, x.label).length)) * 5.6);
  const CELL = 30;
  // Headers are rotated -55°; leave room for the last ones to lean right.
  const lean = Math.max(...traits.slice(-4).map((x, k) => tr(lang, x.label).length * 6.6 * Math.cos((55 * Math.PI) / 180) - (3 - k) * CELL));
  const W = LEFT + traits.length * CELL + Math.max(4, lean + 8);
  const H = TOP + rows.length * CELL + 8;
  return (
    <div>
      <div class="overflow-x-auto" tabIndex={0} role="region" aria-label={t("heatmapRegion")}>
        <svg viewBox={`0 0 ${W} ${H}`} class="h-auto w-full min-w-[640px]" role="img" aria-label={t("heatmapSvg")}>
          {traits.map((x, j) => (
            <text key={x.id} transform={`translate(${LEFT + j * CELL + CELL / 2 + 4} ${TOP - 8}) rotate(-55)`} class="fill-malam-950 text-[12px] dark:fill-kafan-100">
              {tr(lang, x.label)}
            </text>
          ))}
          {rows.map((r, i) => {
            const y = TOP + i * CELL;
            const last = i === rows.length - 1;
            return (
              <g key={r.label}>
                {!last && <circle cx={10} cy={y + CELL / 2} r={5} style={{ fill: cladeVar(r.key) }} />}
                <text x={last ? 4 : 20} y={y + CELL / 2 + 4} class={`fill-malam-950 text-[12.5px] dark:fill-kafan-100 ${last ? "font-bold" : ""}`}>
                  {r.label} ({r.ghosts.length})
                </text>
                {traits.map((x, j) => {
                  const n = r.ghosts.filter((g) => g.traits[x.id] === 1).length;
                  const p = pct(n, r.ghosts.length);
                  const msg = t("heatSays", r.label, p, tr(lang, x.label), n, r.ghosts.length);
                  return (
                    <rect
                      key={x.id}
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
      <ul class="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs" aria-label={t("colorScale")}>
        <li class="font-semibold">{t("heatScale")}</li>
        {["0%", "1–20%", "21–40%", "41–60%", "61–80%", "81–100%"].map((l, i) => <Swatch key={l} color={SEQ[i]} label={l} />)}
      </ul>
      <Readout text={hover} idle={t("heatIdle")} />
      <DataTable
        lang={lang}
        caption={t("heatTableCap")}
        head={[t("clade"), ...traits.map((x) => tr(lang, x.label))]}
        rows={rows.map((r) => [r.label, ...traits.map((x) => `${pct(r.ghosts.filter((g) => g.traits[x.id] === 1).length, r.ghosts.length)}%`)])}
      />
    </div>
  );
}

/* ---- 3. Danger unit chart -------------------------------------------------- */

export function DangerUnits({ lang }: { lang: Lang }) {
  const t = useT(lang);
  const [hover, setHover] = useState<Ghost | null>(null);
  return (
    <div>
      <div class="overflow-x-auto" tabIndex={0} role="region" aria-label={t("dangerRegion")}>
        <table class="w-full min-w-[640px] border-separate border-spacing-y-1 text-sm">
          <caption class="sr-only">{t("dangerCap")}</caption>
          <thead>
            <tr>
              <th scope="col" class="w-44 text-left font-semibold">{t("clade")}</th>
              {[1, 2, 3, 4, 5].map((d) => (
                <th key={d} scope="col" class="px-1 text-left font-semibold">
                  {d} · {dangerLabel(lang, d)}
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
                    {tr(lang, c)}
                  </span>
                </th>
                {[1, 2, 3, 4, 5].map((d) => {
                  const gs = data.ghosts.filter((g) => g.clade === c && g.danger === d);
                  return (
                    <td key={d} class="rounded-xl bg-kafan-100/80 p-1 align-top dark:bg-malam-900/80">
                      <ul class="flex flex-wrap gap-0.5" aria-label={`${tr(lang, c)}, ${dangerLabel(lang, d)}: ${gs.length ? gs.map((g) => g.name).join(", ") : t("none")}`}>
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
      <Readout text={hover ? t("dangerSays", hover.name, tr(lang, hover.clade), hover.danger, dangerLabel(lang, hover.danger)) : null} idle={t("dangerIdle")} />
    </div>
  );
}

/* ---- 4. Body plan × diet bubble matrix ------------------------------------- */

export function BodyDiet({ lang }: { lang: Lang }) {
  const t = useT(lang);
  const [hover, setHover] = useState<string | null>(null);
  const diets = [...data.characters[19].states, "Unknown"];
  const plans = data.bodyPlans.filter((b) => data.ghosts.some((g) => g.bodyPlan === b.id));
  const count = (plan: string, diet: string) =>
    data.ghosts.filter((g) => g.bodyPlan === plan && (g.dietClass ?? "Unknown") === diet);
  const max = Math.max(...plans.flatMap((p) => diets.map((d) => count(p.id, d).length)));
  const CELL = 56;
  const ROW = 30;
  const LEFT = Math.max(200, 20 + Math.max(...plans.map((p) => tr(lang, p.label).length)) * 7);
  const headerLen = Math.max(...diets.map((d) => tr(lang, d).length));
  const TOP = Math.max(70, Math.ceil(22 + headerLen * 6.6 * Math.sin((25 * Math.PI) / 180)));
  // Diet headers are rotated -25°; leave room for the last ones to lean right.
  const lean = Math.max(...diets.slice(-3).map((d, k) => tr(lang, d).length * 6.6 * Math.cos((25 * Math.PI) / 180) - (2 - k) * CELL - CELL / 2));
  const W = LEFT + diets.length * CELL + Math.max(0, lean + 8);
  const H = TOP + plans.length * ROW + 6;
  return (
    <div>
      <div class="overflow-x-auto" tabIndex={0} role="region" aria-label={t("bodyRegion")}>
        <svg viewBox={`0 0 ${W} ${H}`} class="h-auto w-full min-w-[560px]" role="img" aria-label={t("bodySvg")}>
          {diets.map((d, j) => (
            <text key={d} transform={`translate(${LEFT + j * CELL + CELL / 2} ${TOP - 10}) rotate(-25)`} class="fill-malam-950 text-[12px] dark:fill-kafan-100">
              {tr(lang, d)}
            </text>
          ))}
          {plans.map((p, i) => {
            const y = TOP + i * ROW + ROW / 2;
            return (
              <g key={p.id}>
                <line x1={LEFT} x2={W} y1={y} y2={y} class="stroke-kafan-300 dark:stroke-malam-800" />
                <text x={LEFT - 10} y={y + 4} text-anchor="end" class="fill-malam-950 text-[12.5px] dark:fill-kafan-100">{tr(lang, p.label)}</text>
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
                      onMouseEnter={() => setHover(t("bodySays", tr(lang, p.label), tr(lang, d), gs.map((g) => g.name).join(", ")))}
                      onMouseLeave={() => setHover(null)}
                    />
                  );
                })}
              </g>
            );
          })}
        </svg>
      </div>
      <Readout text={hover} idle={t("bodyIdle")} />
      <DataTable
        lang={lang}
        caption={t("bodyTableCap")}
        head={[t("bodyPlan"), ...diets.map((d) => tr(lang, d))]}
        rows={plans.map((p) => [tr(lang, p.label), ...diets.map((d) => count(p.id, d).length)])}
      />
    </div>
  );
}

/* ---- 5. Coding provenance bars --------------------------------------------- */

const CODING = [
  { key: "source", label: "provSource" as Key, color: "var(--seq-5)" },
  { key: "filled", label: "provFilled" as Key, color: "var(--seq-2)" },
  { key: "new", label: "provNew" as Key, color: "var(--seq-1)" },
] as const;

export function Provenance({ lang }: { lang: Lang }) {
  const t = useT(lang);
  const [hover, setHover] = useState<string | null>(null);
  const max = Math.max(...data.clades.map((c) => data.ghosts.filter((g) => g.clade === c).length));
  return (
    <div>
      <ul class="flex flex-wrap gap-x-4 gap-y-1 text-xs" aria-label={t("legend")}>
        {CODING.map((c) => <Swatch key={c.key} color={c.color} label={t(c.label)} />)}
      </ul>
      <ul class="mt-3 space-y-1.5">
        {data.clades.map((c) => {
          const gs = data.ghosts.filter((g) => g.clade === c);
          return (
            <li key={c} class="grid grid-cols-[minmax(0,11rem)_1fr] items-center gap-3 text-sm">
              <span class="inline-flex items-center gap-1.5">
                <span class="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: cladeVar(c) }} />
                {tr(lang, c)}
              </span>
              <span class="flex h-6 gap-0.5" style={{ width: `${(gs.length / max) * 100}%` }} aria-label={`${tr(lang, c)}: ${CODING.map((k) => `${gs.filter((g) => g.coding === k.key).length} ${t(k.label).toLowerCase()}`).join(", ")}`} role="img">
                {CODING.map((k) => {
                  const n = gs.filter((g) => g.coding === k.key).length;
                  if (!n) return null;
                  return (
                    <span
                      key={k.key}
                      class="flex items-center justify-center rounded-[4px] text-[11px] font-bold first:rounded-l-md last:rounded-r-md"
                      style={{ flex: n, background: k.color, color: k.key === "source" ? "var(--seq-0)" : "var(--seq-5)" }}
                      onMouseEnter={() => setHover(t("provSays", tr(lang, c), n, gs.length, t(k.label)))}
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
      <Readout text={hover} idle={t("provIdle")} />
    </div>
  );
}

/* ---- 6. Support histogram --------------------------------------------------- */

export function SupportHistogram({ lang, supports }: { lang: Lang; supports: number[] }) {
  const t = useT(lang);
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
      <svg viewBox={`0 0 ${W} ${H}`} class="h-auto w-full" role="img" aria-label={t("supportSvg", supports.length)}>
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
            <g key={i} onMouseEnter={() => setHover(t("supportSays", b.n, b.from, b.to))} onMouseLeave={() => setHover(null)}>
              <rect x={x} y={8} width={bw} height={plotH} class="fill-transparent" />
              <path d={`M${x + 2} ${8 + plotH} V${8 + plotH - h + 4} q0 -4 4 -4 H${x + bw - 6} q4 0 4 4 V${8 + plotH} Z`} class={b.from >= 90 ? "fill-darah-700 dark:fill-prada-300" : "fill-malam-600 dark:fill-kemenyan-400"} />
              <text x={x + bw / 2} y={H - 10} text-anchor="middle" class="fill-malam-950 text-[11px] dark:fill-kafan-100">{b.from}</text>
            </g>
          );
        })}
      </svg>
      <Readout text={hover} idle={t("supportIdle")} />
      <DataTable lang={lang} caption={t("supportCap")} head={[t("support"), t("nodes")]} rows={bins.map((b) => [`${b.from}–${b.to}`, b.n])} />
    </div>
  );
}

/* ---- 7. Twins ---------------------------------------------------------------- */

export function Twins({ lang }: { lang: Lang }) {
  const t = useT(lang);
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
                {j > 0 && (j === set.length - 1 ? ` ${t("and")} ` : ", ")}
                <a href={localePath(lang, `/ghosts/${g.id}`)} class="font-semibold underline decoration-kafan-500 underline-offset-2 hover:decoration-darah-600">{g.name}</a>
              </span>
            ))}
          </p>
        </li>
      ))}
    </ul>
  );
}
