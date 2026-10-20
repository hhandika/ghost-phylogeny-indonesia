/**
 * Design C, "Bestiary": a field guide. Specimen cards in tree order, filters
 * for clade, island, danger, and traits, a detail dialog, and a side-by-side
 * comparison of two ghosts that names their common ancestor's support.
 */
import { useEffect, useMemo, useRef, useState } from "preact/hooks";
import { byId, cladeVar, data, DANGER, plateUrl, type Ghost } from "../utils/data";
import { ancestry, layout } from "../utils/tree";
import GhostCard, { CladePill, DangerMeter } from "./GhostCard";

type Sort = "tree" | "name" | "danger";

export default function Bestiary() {
  const L = useMemo(() => layout(data.tree, (id) => byId.get(id)!.clade, "cladogram"), []);
  const treeOrder = new Map(L.tips.map((t) => [t.id!, t.y]));
  const tipById = new Map(L.tips.map((t) => [t.id!, t]));

  const [query, setQuery] = useState("");
  const [clades, setClades] = useState<Set<string>>(new Set());
  const [region, setRegion] = useState("");
  const [minDanger, setMinDanger] = useState(1);
  const [traits, setTraits] = useState<Set<string>>(new Set());
  const [sort, setSort] = useState<Sort>("tree");
  const [open, setOpen] = useState<string | null>(null);
  const [compare, setCompare] = useState<string[]>([]);
  const [showCompare, setShowCompare] = useState(false);

  const toggle = (set: Set<string>, v: string) => {
    const next = new Set(set);
    next.has(v) ? next.delete(v) : next.add(v);
    return next;
  };

  const q = query.trim().toLowerCase();
  const list = data.ghosts
    .filter(
      (g) =>
        (!q || [g.name, g.region, g.culture ?? "", g.behavior ?? ""].some((s) => s.toLowerCase().includes(q))) &&
        (!clades.size || clades.has(g.clade)) &&
        (!region || g.regionGroup === region) &&
        g.danger >= minDanger &&
        [...traits].every((t) => g.traits[t] === 1),
    )
    .sort((a, b) =>
      sort === "name" ? a.name.localeCompare(b.name) : sort === "danger" ? b.danger - a.danger || a.name.localeCompare(b.name) : treeOrder.get(a.id)! - treeOrder.get(b.id)!,
    );

  const pick = (id: string) =>
    setCompare((c) => (c.includes(id) ? c.filter((x) => x !== id) : [...c.slice(-1), id]));

  const reset = () => {
    setQuery("");
    setClades(new Set());
    setRegion("");
    setMinDanger(1);
    setTraits(new Set());
  };

  const chip = (on: boolean) =>
    `rounded-full border px-3 py-1 text-xs transition ${
      on
        ? "border-malam-900 bg-malam-900 text-prada-200 dark:border-prada-300 dark:bg-prada-300 dark:text-malam-950"
        : "border-kafan-300 hover:bg-kafan-200 dark:border-malam-700 dark:hover:bg-malam-800"
    }`;

  return (
    <div class="mx-auto max-w-7xl">
      <section class="rounded-3xl border border-kafan-300 bg-kafan-50/80 p-4 dark:border-malam-700 dark:bg-malam-950/70" aria-label="Filters">
        <div class="flex flex-wrap items-center gap-3">
          <label class="flex min-w-[14rem] flex-1 items-center gap-2 rounded-full border border-kafan-300 bg-kafan-100 px-3 py-1.5 dark:border-malam-700 dark:bg-malam-900">
            <span class="sr-only">Search</span>
            <svg class="h-4 w-4 opacity-60" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="11" cy="11" r="7" /><path d="m20 20-3.5-3.5" /></svg>
            <input
              type="search"
              value={query}
              placeholder="Search names, places, behaviour"
              onInput={(e) => setQuery((e.target as HTMLInputElement).value)}
              class="w-full bg-transparent text-sm outline-none placeholder:text-kafan-600 dark:placeholder:text-kemenyan-400"
            />
          </label>
          <select
            aria-label="Island"
            value={region}
            onChange={(e) => setRegion((e.target as HTMLSelectElement).value)}
            class="rounded-full border border-kafan-300 bg-kafan-100 px-3 py-1.5 text-sm dark:border-malam-700 dark:bg-malam-900"
          >
            <option value="">All islands</option>
            {data.regions.map((r) => (
              <option key={r} value={r}>{r}</option>
            ))}
          </select>
          <select
            aria-label="Minimum danger"
            value={minDanger}
            onChange={(e) => setMinDanger(Number((e.target as HTMLSelectElement).value))}
            class="rounded-full border border-kafan-300 bg-kafan-100 px-3 py-1.5 text-sm dark:border-malam-700 dark:bg-malam-900"
          >
            {[1, 2, 3, 4, 5].map((d) => (
              <option key={d} value={d}>{d === 1 ? "Any danger" : `${DANGER[d]} or worse`}</option>
            ))}
          </select>
          <select
            aria-label="Sort"
            value={sort}
            onChange={(e) => setSort((e.target as HTMLSelectElement).value as Sort)}
            class="rounded-full border border-kafan-300 bg-kafan-100 px-3 py-1.5 text-sm dark:border-malam-700 dark:bg-malam-900"
          >
            <option value="tree">Tree order</option>
            <option value="name">Name</option>
            <option value="danger">Most dangerous</option>
          </select>
        </div>
        <div class="mt-3 flex flex-wrap gap-1.5" role="group" aria-label="Clades">
          {data.clades.map((c) => (
            <button key={c} type="button" aria-pressed={clades.has(c)} onClick={() => setClades(toggle(clades, c))} class={`${chip(clades.has(c))} inline-flex items-center gap-1.5`}>
              <span class="h-2 w-2 rounded-full" style={{ background: cladeVar(c) }} />
              {c}
            </button>
          ))}
        </div>
        <div class="mt-2 flex flex-wrap gap-1.5" role="group" aria-label="Traits, all must be present">
          {data.characters.slice(0, 18).filter((c) => c.id !== "sex").map((c) => (
            <button key={c.id} type="button" aria-pressed={traits.has(c.id)} onClick={() => setTraits(toggle(traits, c.id))} class={chip(traits.has(c.id))}>
              {c.label}
            </button>
          ))}
        </div>
        <p class="mt-3 text-xs text-kafan-700 dark:text-kemenyan-300" aria-live="polite">
          {list.length} of {data.ghosts.length} specimens.{" "}
          {list.length < data.ghosts.length && (
            <button type="button" onClick={reset} class="font-semibold text-darah-700 underline underline-offset-2 dark:text-prada-300">
              Clear filters
            </button>
          )}
        </p>
      </section>

      <ul class="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
        {list.map((g) => (
          <li key={g.id} class="group relative">
            <button
              type="button"
              onClick={() => setOpen(g.id)}
              class="flex h-full w-full flex-col items-center rounded-3xl border border-kafan-300 bg-kafan-50/90 p-3 pb-10 text-center transition hover:-translate-y-0.5 hover:border-darah-400 hover:shadow-lg dark:border-malam-700 dark:bg-malam-900/80 dark:hover:border-prada-400"
            >
              <span class="block h-1 w-12 rounded-full" style={{ background: cladeVar(g.clade) }} />
              <img src={plateUrl(g.id)} alt="" width={112} height={112} loading="lazy" class="mt-2 rounded-full transition duration-500 group-hover:scale-105" />
              <span class="mt-2 font-serif text-lg font-semibold leading-tight">{g.name}</span>
              <span class="mt-0.5 text-xs text-kafan-700 dark:text-kemenyan-300">{g.regionGroup === "Outgroup" ? g.region.replace(" (Outgroup)", "") : g.regionGroup}</span>
              <span class="mt-1 text-[11px] leading-snug text-kafan-700 dark:text-kemenyan-400">{g.clade}</span>
              <span class="mt-2"><DangerMeter level={g.danger} /></span>
            </button>
            <label class="absolute bottom-3 left-1/2 flex -translate-x-1/2 cursor-pointer items-center gap-1 text-[11px] text-kafan-700 dark:text-kemenyan-300">
              <input type="checkbox" checked={compare.includes(g.id)} onChange={() => pick(g.id)} class="accent-darah-600" />
              Compare
            </label>
          </li>
        ))}
      </ul>

      {compare.length > 0 && (
        <div class="fixed inset-x-0 bottom-4 z-40 mx-auto flex w-fit items-center gap-3 rounded-full border border-kafan-300 bg-kafan-50/95 py-1.5 pl-2 pr-2 shadow-xl backdrop-blur dark:border-malam-700 dark:bg-malam-900/95">
          {compare.map((id) => (
            <img key={id} src={plateUrl(id)} alt={byId.get(id)!.name} width={36} height={36} class="rounded-full" />
          ))}
          <span class="text-sm">{compare.length === 1 ? "Pick one more" : "Ready"}</span>
          <button
            type="button"
            disabled={compare.length < 2}
            onClick={() => setShowCompare(true)}
            class="rounded-full bg-malam-900 px-4 py-1.5 text-sm font-semibold text-prada-200 disabled:opacity-40 dark:bg-prada-300 dark:text-malam-950"
          >
            Compare
          </button>
          <button type="button" onClick={() => setCompare([])} class="px-2 text-sm underline">
            Clear
          </button>
        </div>
      )}

      {open && (
        <Dialog label={byId.get(open)!.name} onClose={() => setOpen(null)}>
          <GhostCard ghost={byId.get(open)!} onSelect={setOpen} />
        </Dialog>
      )}
      {showCompare && compare.length === 2 && (
        <Dialog label="Comparison" onClose={() => setShowCompare(false)} wide>
          <Compare a={byId.get(compare[0])!} b={byId.get(compare[1])!} ancestors={(id) => ancestry(tipById.get(id))} />
        </Dialog>
      )}
    </div>
  );
}

function Dialog({ label, onClose, wide = false, children }: { label: string; onClose: () => void; wide?: boolean; children: preact.ComponentChildren }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const before = document.activeElement as HTMLElement | null;
    ref.current?.focus();
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    document.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = "";
      before?.focus();
    };
  }, []);
  return (
    <div class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-malam-950/60 p-4 backdrop-blur-sm sm:items-center" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div ref={ref} tabIndex={-1} role="dialog" aria-modal="true" aria-label={label} class={`relative my-6 w-full outline-none ${wide ? "max-w-3xl" : "max-w-xl"}`}>
        <button
          type="button"
          onClick={onClose}
          aria-label="Close"
          class="absolute -top-3 right-0 z-10 flex h-9 w-9 items-center justify-center rounded-full border border-kafan-300 bg-kafan-100 dark:border-malam-700 dark:bg-malam-800 sm:-right-3"
        >
          ✕
        </button>
        {children}
      </div>
    </div>
  );
}

function Compare({ a, b, ancestors }: { a: Ghost; b: Ghost; ancestors: (id: string) => Set<unknown> }) {
  const pa = [...ancestors(a.id)];
  const pb = ancestors(b.id);
  const mrca = pa.find((p) => pb.has(p)) as { support?: number; tips: string[] } | undefined;
  const steps = pa.indexOf(mrca as never) + [...pb].indexOf(mrca);
  const diffs = data.characters.filter((_, i) => a.row[i] !== b.row[i]).length;
  const state = (g: Ghost, i: number) => {
    const s = g.row[i];
    return s === "?" ? "Unknown" : data.characters[i].states[data.symbols.indexOf(s)];
  };
  return (
    <article class="rounded-3xl border border-kafan-300 bg-kafan-50 p-5 dark:border-malam-700 dark:bg-malam-900">
      <div class="grid grid-cols-2 gap-4 text-center">
        {[a, b].map((g) => (
          <div key={g.id}>
            <img src={plateUrl(g.id)} alt="" width={112} height={112} class="mx-auto rounded-full" />
            <h3 class="mt-2 font-serif text-xl font-semibold">{g.name}</h3>
            <div class="mt-1"><CladePill clade={g.clade} /></div>
          </div>
        ))}
      </div>
      <p class="mt-4 rounded-2xl bg-kafan-200/70 p-3 text-sm dark:bg-malam-800">
        They differ in {diffs} of {data.characters.length} characters and sit {steps} branches apart. Their last common ancestor unites {mrca?.tips.length ?? "?"} ghosts
        {mrca?.support !== undefined ? ` (ultrafast bootstrap ${mrca.support})` : ""}.
      </p>
      <table class="mt-4 w-full text-left text-sm">
        <thead>
          <tr class="text-xs uppercase tracking-wider text-kafan-600 dark:text-kemenyan-400">
            <th class="py-1 font-semibold">Character</th>
            <th class="py-1 font-semibold">{a.name}</th>
            <th class="py-1 font-semibold">{b.name}</th>
          </tr>
        </thead>
        <tbody>
          {data.characters.map((c, i) => {
            const same = a.row[i] === b.row[i];
            return (
              <tr key={c.id} class={`border-t border-kafan-200 dark:border-malam-800 ${same ? "opacity-60" : ""}`}>
                <td class="py-1 pr-2 font-semibold">{c.label}</td>
                <td class={`py-1 pr-2 ${same ? "" : "text-darah-700 dark:text-prada-300"}`}>{state(a, i)}</td>
                <td class={`py-1 ${same ? "" : "text-darah-700 dark:text-prada-300"}`}>{state(b, i)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </article>
  );
}
