/**
 * Design A, "Atlas": the classic phylogenetics figure. A rectangular tree on
 * the left, tip plates and names, and the coded trait matrix aligned to the
 * tips, with a sticky detail card. Built for desktop reading; scrolls
 * sideways on phones.
 */
import { useMemo, useState } from "preact/hooks";
import { byId, cladeVar, data, plateUrl } from "../utils/data";
import { ancestry, connector, elbow, layout, type Mode } from "../utils/tree";
import GhostCard from "./GhostCard";

const ROW = 22;
const TOP = 96; // room for the rotated matrix headers
const TREE_W = 330;
const LABEL_W = 196;
const CELL = 13;

export default function Atlas() {
  const [mode, setMode] = useState<Mode>("cladogram");
  const [selected, setSelected] = useState<string>(data.ghosts[0].id);
  const [query, setQuery] = useState("");
  const [trait, setTrait] = useState("");
  const [hover, setHover] = useState<string | null>(null);

  const cladeOf = (id: string) => byId.get(id)!.clade;
  const L = useMemo(() => layout(data.tree, cladeOf, mode), [mode]);
  const sx = (x: number) => 8 + (x / L.maxX) * (TREE_W - 16);
  const sy = (y: number) => TOP + y * ROW + ROW / 2;
  const labelX = TREE_W + 4;
  const matrixX = TREE_W + LABEL_W;
  const W = matrixX + data.characters.length * CELL + 8;
  const H = TOP + L.nTips * ROW + 8;

  const q = query.trim().toLowerCase();
  const matches = (id: string) => {
    const g = byId.get(id)!;
    const okQuery = !q || g.name.toLowerCase().includes(q) || g.region.toLowerCase().includes(q);
    const okTrait = !trait || g.traits[trait] === 1;
    return okQuery && okTrait;
  };
  const tipById = new Map(L.tips.map((t) => [t.id!, t]));
  const path = ancestry(tipById.get(selected));
  const ghost = byId.get(selected)!;
  const nMatch = L.tips.filter((t) => matches(t.id!)).length;

  const select = (id: string) => {
    setSelected(id);
    document.getElementById(`row-${id}`)?.scrollIntoView({ block: "nearest", behavior: "smooth" });
  };

  const cellFill = (state: string, i: number) => {
    if (state === "?") return "fill-transparent";
    if (i >= 18) return "fill-kafan-300 dark:fill-malam-700"; // multistate: letter shown on top
    if (state === "1") return "fill-malam-800 dark:fill-prada-300";
    if (state === "2") return "fill-kemenyan-400 dark:fill-kemenyan-500";
    return "fill-kafan-200 dark:fill-malam-800";
  };

  return (
    <div class="mx-auto max-w-7xl">
      <div class="sticky top-[4.5rem] z-30 mb-4 flex flex-wrap items-center gap-3 rounded-2xl border border-kafan-300 bg-kafan-100/90 p-3 backdrop-blur dark:border-malam-700 dark:bg-malam-950/90">
        <label class="flex min-w-[12rem] flex-1 items-center gap-2 rounded-full border border-kafan-300 bg-kafan-50 px-3 py-1.5 dark:border-malam-700 dark:bg-malam-900">
          <span class="sr-only">Search ghosts</span>
          <svg class="h-4 w-4 opacity-60" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="11" cy="11" r="7" /><path d="m20 20-3.5-3.5" /></svg>
          <input
            type="search"
            value={query}
            placeholder="Search by name or island"
            onInput={(e) => setQuery((e.target as HTMLInputElement).value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                const first = L.tips.find((t) => matches(t.id!));
                if (first) select(first.id!);
              }
            }}
            class="w-full bg-transparent text-sm outline-none placeholder:text-kafan-600 dark:placeholder:text-kemenyan-400"
          />
        </label>
        <label class="flex items-center gap-2 text-sm">
          <span class="font-semibold">Highlight</span>
          <select
            value={trait}
            onChange={(e) => setTrait((e.target as HTMLSelectElement).value)}
            class="rounded-full border border-kafan-300 bg-kafan-50 px-3 py-1.5 dark:border-malam-700 dark:bg-malam-900"
          >
            <option value="">No trait</option>
            {data.characters.slice(0, 18).filter((c) => c.id !== "sex").map((c) => (
              <option key={c.id} value={c.id}>{c.label}</option>
            ))}
          </select>
        </label>
        <div class="flex rounded-full border border-kafan-300 p-0.5 text-sm dark:border-malam-700" role="group" aria-label="Branch lengths">
          {(["cladogram", "phylogram"] as Mode[]).map((m) => (
            <button
              key={m}
              type="button"
              aria-pressed={mode === m}
              onClick={() => setMode(m)}
              class={`rounded-full px-3 py-1 capitalize transition ${mode === m ? "bg-malam-900 text-prada-200 dark:bg-prada-300 dark:text-malam-950" : "hover:bg-kafan-200 dark:hover:bg-malam-800"}`}
            >
              {m}
            </button>
          ))}
        </div>
        <p class="text-xs text-kafan-700 dark:text-kemenyan-300" aria-live="polite">
          {nMatch} of {L.nTips} shown
        </p>
      </div>

      <div class="grid gap-6 lg:grid-cols-[minmax(0,1fr)_24rem]">
        <figure class="overflow-x-auto rounded-3xl border border-kafan-300 bg-kafan-50/80 p-2 dark:border-malam-700 dark:bg-malam-950/70">
          <svg
            viewBox={`0 0 ${W} ${H}`}
            class="block h-auto w-full min-w-[680px]"
            role="img"
            aria-label={`Maximum-likelihood tree of ${L.nTips} ghosts with their coded traits. ${ghost.name} is selected.`}
          >
            {/* Matrix headers */}
            {data.characters.map((c, i) => (
              <text
                key={c.id}
                transform={`translate(${matrixX + i * CELL + CELL / 2 + 3} ${TOP - 6}) rotate(-60)`}
                class={`text-[10px] ${trait === c.id ? "fill-darah-700 font-bold dark:fill-prada-300" : "fill-kafan-700 dark:fill-kemenyan-300"}`}
              >
                {c.label}
              </text>
            ))}

            {/* Row bands for selected and hovered tips */}
            {L.tips.map((t) =>
              t.id === selected || t.id === hover ? (
                <rect
                  key={`band-${t.id}`}
                  x={0}
                  y={sy(t.y) - ROW / 2}
                  width={W}
                  height={ROW}
                  rx={6}
                  class={t.id === selected ? "fill-prada-200/70 dark:fill-malam-800" : "fill-kafan-200/60 dark:fill-malam-900"}
                />
              ) : null,
            )}

            {/* Branches */}
            <g fill="none" stroke-linecap="round">
              {L.all.map((p, i) => {
                const onPath = path.has(p);
                const color = p.clade ? cladeVar(p.clade) : "var(--neutral-branch)";
                return (
                  <g key={i}>
                    <path d={elbow(p, sx, sy)} stroke={color} stroke-width={onPath ? 3.5 : 1.6} />
                    <path d={connector(p, sx, sy)} stroke={p.clade ? color : "var(--neutral-branch)"} stroke-width={1.6} />
                  </g>
                );
              })}
            </g>

            {/* Node support: filled ≥ 95, open 80–94 */}
            {L.all
              .filter((p) => p.children.length && p.support !== undefined && p.support >= 80)
              .map((p, i) => (
                <circle
                  key={`s${i}`}
                  cx={sx(p.x)}
                  cy={sy(p.y)}
                  r={3.4}
                  class={p.support! >= 95 ? "fill-malam-900 stroke-kafan-50 dark:fill-kafan-100 dark:stroke-malam-950" : "fill-kafan-50 stroke-malam-900 dark:fill-malam-950 dark:stroke-kafan-100"}
                  stroke-width={1.4}
                >
                  <title>UFBoot {p.support}</title>
                </circle>
              ))}

            {/* Tips: leader, plate, name, matrix row */}
            {L.tips.map((t) => {
              const g = byId.get(t.id!)!;
              const y = sy(t.y);
              const on = matches(t.id!);
              return (
                <g
                  key={t.id}
                  id={`row-${t.id}`}
                  class="cursor-pointer"
                  opacity={on ? 1 : 0.22}
                  onClick={() => select(t.id!)}
                  onMouseEnter={() => setHover(t.id!)}
                  onMouseLeave={() => setHover(null)}
                  role="button"
                  tabIndex={0}
                  aria-label={`${g.name}, ${g.clade}`}
                  onKeyDown={(e) => (e.key === "Enter" || e.key === " ") && (e.preventDefault(), select(t.id!))}
                >
                  {mode === "phylogram" && (
                    <path d={`M${sx(t.x) + 2} ${y} H${labelX}`} class="stroke-kafan-400 dark:stroke-malam-600" stroke-dasharray="1 3" />
                  )}
                  <image href={plateUrl(g.id)} x={labelX} y={y - 9} width={18} height={18} />
                  <text x={labelX + 23} y={y + 4} class={`text-[12px] ${t.id === selected ? "fill-darah-800 font-bold dark:fill-prada-200" : "fill-malam-950 dark:fill-kafan-100"}`}>
                    {g.name}
                    {g.outgroup ? " †" : ""}
                    {g.coding !== "source" ? " ◆" : ""}
                  </text>
                  {g.row.split("").map((s, i) => (
                    <g key={i}>
                      <rect x={matrixX + i * CELL} y={y - CELL / 2 + 1} width={CELL - 2} height={CELL - 2} rx={2} class={cellFill(s, i)} />
                      {s === "?" && <circle cx={matrixX + i * CELL + CELL / 2 - 1} cy={y + 0.5} r={1.2} class="fill-kafan-500" />}
                      {i >= 18 && s !== "?" && (
                        <text x={matrixX + i * CELL + CELL / 2 - 1} y={y + 4} text-anchor="middle" class="fill-malam-900 text-[8px] font-bold dark:fill-kafan-100">
                          {s}
                        </text>
                      )}
                      <title>{`${g.name} · ${data.characters[i].label}: ${s === "?" ? "unknown" : data.characters[i].states[data.symbols.indexOf(s)]}`}</title>
                    </g>
                  ))}
                </g>
              );
            })}
          </svg>
          <figcaption class="px-3 pb-3 pt-2 text-xs leading-relaxed text-kafan-700 dark:text-kemenyan-300">
            Branches take the clade colour where every tip below shares it. Filled dots mark ultrafast bootstrap ≥ 95, open dots 80–94. In the matrix, dark cells are present, pale cells absent, grey cells variable; the last two columns are body plan and diet as state codes. † outgroup, ◆ some or all traits coded by folklore synthesis.
          </figcaption>
        </figure>

        <aside class="lg:sticky lg:top-40 lg:self-start">
          <GhostCard ghost={ghost} onSelect={select} />
        </aside>
      </div>
    </div>
  );
}
