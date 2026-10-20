/**
 * "Bestiary": a field guide. Specimen cards in tree order, filters
 * for clade, island, danger, and traits, a detail dialog, and a side-by-side
 * comparison of two ghosts that names their common ancestor's support.
 */
import { useEffect, useMemo, useRef, useState } from "preact/hooks";
import { byId, cladeVar, data, plateUrl, type Ghost } from "../utils/data";
import { dangerLabel, regionName, tr, useT, type Lang } from "../i18n";
import { ancestry, layout } from "../utils/tree";
import GhostCard, { CladePill, DangerMeter } from "./GhostCard";

type Sort = "tree" | "name" | "danger";

export default function Bestiary({ lang }: { lang: Lang }) {
  const t = useT(lang);
  const L = useMemo(() => layout(data.tree, (id) => byId.get(id)!.clade, "cladogram"), []);
  const treeOrder = new Map(L.tips.map((tip) => [tip.id!, tip.y]));
  const tipById = new Map(L.tips.map((tip) => [tip.id!, tip]));

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
        (!q || [g.name, g.region, g.culture, g.behavior, tr(lang, g.region), tr(lang, g.culture), tr(lang, g.behavior)].some((s) => (s ?? "").toLowerCase().includes(q))) &&
        (!clades.size || clades.has(g.clade)) &&
        (!region || g.regionGroup === region) &&
        g.danger >= minDanger &&
        [...traits].every((k) => g.traits[k] === 1),
    )
    .sort((a, b) =>
      sort === "name" ? a.name.localeCompare(b.name, lang) : sort === "danger" ? b.danger - a.danger || a.name.localeCompare(b.name) : treeOrder.get(a.id)! - treeOrder.get(b.id)!,
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
        : "border-kafan-700 hover:bg-kafan-200 dark:border-kemenyan-400 dark:hover:bg-malam-800"
    }`;

  return (
    <div class="mx-auto max-w-7xl pb-16">
      <section class="glass p-4" aria-label={t("filters")}>
        <div class="flex flex-wrap items-center gap-3">
          <label class="flex min-w-[14rem] flex-1 items-center gap-2 control px-3 py-1.5">
            <span class="sr-only">{t("search")}</span>
            <svg class="h-4 w-4 opacity-60" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="11" cy="11" r="7" /><path d="m20 20-3.5-3.5" /></svg>
            <input
              type="search"
              value={query}
              placeholder={t("searchBestiary")}
              onInput={(e) => setQuery((e.target as HTMLInputElement).value)}
              class="w-full bg-transparent text-sm outline-none placeholder:text-kafan-800 dark:placeholder:text-kemenyan-300"
            />
          </label>
          <select
            aria-label={t("island")}
            value={region}
            onChange={(e) => setRegion((e.target as HTMLSelectElement).value)}
            class="control px-3 py-1.5 text-sm"
          >
            <option value="">{t("allIslands")}</option>
            {data.regions.map((r) => (
              <option key={r} value={r}>{regionName(lang, r)}</option>
            ))}
          </select>
          <select
            aria-label={t("minDanger")}
            value={minDanger}
            onChange={(e) => setMinDanger(Number((e.target as HTMLSelectElement).value))}
            class="control px-3 py-1.5 text-sm"
          >
            {[1, 2, 3, 4, 5].map((d) => (
              <option key={d} value={d}>{d === 1 ? t("anyDanger") : t("orWorse", dangerLabel(lang, d))}</option>
            ))}
          </select>
          <select
            aria-label={t("sort")}
            value={sort}
            onChange={(e) => setSort((e.target as HTMLSelectElement).value as Sort)}
            class="control px-3 py-1.5 text-sm"
          >
            <option value="tree">{t("sortTree")}</option>
            <option value="name">{t("sortName")}</option>
            <option value="danger">{t("sortDanger")}</option>
          </select>
        </div>
        <div class="mt-3 flex flex-wrap gap-1.5" role="group" aria-label={t("clades")}>
          {data.clades.map((c) => (
            <button key={c} type="button" aria-pressed={clades.has(c)} onClick={() => setClades(toggle(clades, c))} class={`${chip(clades.has(c))} inline-flex items-center gap-1.5`}>
              <span class="h-2 w-2 rounded-full" style={{ background: cladeVar(c) }} />
              {tr(lang, c)}
            </button>
          ))}
        </div>
        <div class="mt-2 flex flex-wrap gap-1.5" role="group" aria-label={t("traitsAll")}>
          {data.characters.slice(0, 18).filter((c) => c.id !== "sex").map((c) => (
            <button key={c.id} type="button" aria-pressed={traits.has(c.id)} onClick={() => setTraits(toggle(traits, c.id))} class={chip(traits.has(c.id))}>
              {tr(lang, c.label)}
            </button>
          ))}
        </div>
        <p class="mt-3 text-xs muted" aria-live="polite">
          {t("nSpecimens", list.length, data.ghosts.length)}{" "}
          {list.length < data.ghosts.length && (
            <button type="button" onClick={reset} class="font-semibold text-darah-700 underline underline-offset-2 dark:text-prada-300">
              {t("clearFilters")}
            </button>
          )}
        </p>
      </section>

      <ul class="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
        {list.map((g) => (
          <li key={g.id} class="glass group relative transition hover:-translate-y-0.5 hover:!border-darah-600 dark:hover:!border-prada-400">
            <button
              type="button"
              onClick={() => setOpen(g.id)}
              class="flex h-full w-full flex-col items-center rounded-3xl p-3 pb-10 text-center"
            >
              <span class="block h-1 w-12 rounded-full" style={{ background: cladeVar(g.clade) }} />
              <img src={plateUrl(g.id)} alt="" width={112} height={112} loading="lazy" class="mt-2 rounded-full transition duration-500 group-hover:scale-105" />
              <span class="mt-2 font-serif text-lg font-semibold leading-tight">{g.name}</span>
              <span class="mt-0.5 text-xs muted">{g.regionGroup === "Outgroup" ? tr(lang, g.region).replace(/ \((Outgroup|kelompok luar)\)/, "") : tr(lang, g.regionGroup)}</span>
              <span class="muted mt-1 text-xs leading-snug">{tr(lang, g.clade)}</span>
              <span class="mt-2"><DangerMeter level={g.danger} lang={lang} /></span>
            </button>
            <label class="muted absolute bottom-2 left-1/2 flex -translate-x-1/2 cursor-pointer items-center gap-1.5 rounded-full px-2 py-1 text-xs">
              <input type="checkbox" checked={compare.includes(g.id)} onChange={() => pick(g.id)} class="h-4 w-4 accent-darah-700" />
              {t("compare")}<span class="sr-only"> {g.name}</span>
            </label>
          </li>
        ))}
      </ul>

      {compare.length > 0 && (
        <div class="fixed inset-x-0 bottom-4 z-40 mx-auto flex w-fit items-center gap-3 glass glass-solid !rounded-full py-1.5 pl-2 pr-2">
          {compare.map((id) => (
            <img key={id} src={plateUrl(id)} alt={byId.get(id)!.name} width={36} height={36} class="rounded-full" />
          ))}
          <span class="text-sm">{compare.length === 1 ? t("pickOneMore") : t("ready")}</span>
          <button
            type="button"
            disabled={compare.length < 2}
            onClick={() => setShowCompare(true)}
            class="rounded-full bg-malam-900 px-4 py-1.5 text-sm font-semibold text-prada-200 disabled:opacity-40 dark:bg-prada-300 dark:text-malam-950"
          >
            {t("compare")}
          </button>
          <button type="button" onClick={() => setCompare([])} class="px-2 text-sm underline">
            {t("clear")}
          </button>
        </div>
      )}

      {open && (
        <Dialog label={byId.get(open)!.name} closeLabel={t("close")} onClose={() => setOpen(null)}>
          <GhostCard ghost={byId.get(open)!} lang={lang} onSelect={setOpen} />
        </Dialog>
      )}
      {showCompare && compare.length === 2 && (
        <Dialog label={t("comparison")} closeLabel={t("close")} onClose={() => setShowCompare(false)} wide>
          <Compare lang={lang} a={byId.get(compare[0])!} b={byId.get(compare[1])!} ancestors={(id) => ancestry(tipById.get(id))} />
        </Dialog>
      )}
    </div>
  );
}

function Dialog({ label, closeLabel, onClose, wide = false, children }: { label: string; closeLabel: string; onClose: () => void; wide?: boolean; children: preact.ComponentChildren }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const before = document.activeElement as HTMLElement | null;
    ref.current?.focus();
    // Escape closes; Tab stays inside the dialog.
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") return onClose();
      if (e.key !== "Tab" || !ref.current) return;
      const items = [...ref.current.querySelectorAll<HTMLElement>("a[href], button, input, select, summary, [tabindex='0']")];
      if (!items.length) return;
      const first = items[0];
      const last = items[items.length - 1];
      if (e.shiftKey && (document.activeElement === first || document.activeElement === ref.current)) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    };
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
      <div ref={ref} tabIndex={-1} role="dialog" aria-modal="true" aria-label={label} class={`glass-solid relative my-6 w-full outline-none ${wide ? "max-w-3xl" : "max-w-xl"}`}>
        <button
          type="button"
          onClick={onClose}
          aria-label={closeLabel}
          class="control absolute -top-3 right-0 z-10 flex h-10 w-10 items-center justify-center sm:-right-3"
        >
          ✕
        </button>
        {children}
      </div>
    </div>
  );
}

function Compare({ lang, a, b, ancestors }: { lang: Lang; a: Ghost; b: Ghost; ancestors: (id: string) => Set<unknown> }) {
  const t = useT(lang);
  const pa = [...ancestors(a.id)];
  const pb = ancestors(b.id);
  const mrca = pa.find((p) => pb.has(p)) as { support?: number; tips: string[] } | undefined;
  const steps = pa.indexOf(mrca as never) + [...pb].indexOf(mrca);
  const diffs = data.characters.filter((_, i) => a.row[i] !== b.row[i]).length;
  const state = (g: Ghost, i: number) => {
    const s = g.row[i];
    return s === "?" ? t("unknown") : tr(lang, data.characters[i].states[data.symbols.indexOf(s)]);
  };
  return (
    <article class="glass p-5">
      <div class="grid grid-cols-2 gap-4 text-center">
        {[a, b].map((g) => (
          <div key={g.id}>
            <img src={plateUrl(g.id)} alt="" width={112} height={112} class="mx-auto rounded-full" />
            <h3 class="mt-2 font-serif text-xl font-semibold">{g.name}</h3>
            <div class="mt-1"><CladePill clade={g.clade} lang={lang} /></div>
          </div>
        ))}
      </div>
      <p class="mt-4 rounded-2xl bg-kafan-200/70 p-3 text-sm dark:bg-malam-800">
        {t("compareSummary", diffs, data.characters.length, steps, String(mrca?.tips.length ?? "?"), mrca?.support !== undefined ? String(mrca.support) : "")}
      </p>
      <table class="mt-4 w-full text-left text-sm">
        <thead>
          <tr class="text-xs uppercase tracking-wider muted">
            <th scope="col" class="py-1 font-semibold">{t("character")}</th>
            <th scope="col" class="py-1 font-semibold">{a.name}</th>
            <th scope="col" class="py-1 font-semibold">{b.name}</th>
          </tr>
        </thead>
        <tbody>
          {data.characters.map((c, i) => {
            const same = a.row[i] === b.row[i];
            return (
              <tr key={c.id} class={`border-t border-kafan-200 dark:border-malam-800 ${same ? "muted" : ""}`}>
                <th scope="row" class="py-1 pr-2 text-left font-semibold">{tr(lang, c.label)}</th>
                <td class={`py-1 pr-2 ${same ? "" : "accent font-semibold"}`}>{state(a, i)}</td>
                <td class={`py-1 ${same ? "" : "accent font-semibold"}`}>{state(b, i)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </article>
  );
}
