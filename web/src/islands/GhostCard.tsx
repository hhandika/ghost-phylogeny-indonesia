/** Detail card for one ghost, shared by the Atlas, Lantern, and Bestiary views. */
import { byId, cladeVar, plateUrl, type Ghost } from "../utils/data";
import { codingLabel, dangerLabel, localePath, presentTraits, sexLabel, tr, useT, type Lang } from "../i18n";

export function DangerMeter({ level, lang }: { level: number; lang: Lang }) {
  const t = useT(lang);
  return (
    <span class="inline-flex items-center gap-1">
      {[1, 2, 3, 4, 5].map((i) => (
        <span
          key={i}
          aria-hidden="true"
          class={`h-2 w-2 rotate-45 border ${i <= level ? "border-darah-700 bg-darah-700 dark:border-darah-300 dark:bg-darah-300" : "border-kafan-700 dark:border-kemenyan-400"}`}
        />
      ))}
      <span class="muted ml-1 text-xs">
        <span class="sr-only">{t("dangerOf", level)} </span>
        {dangerLabel(lang, level)}
      </span>
    </span>
  );
}

export function CladePill({ clade, lang }: { clade: string; lang: Lang }) {
  return (
    <span class="inline-flex items-center gap-1.5 rounded-full border border-kafan-700 px-2.5 py-0.5 text-xs font-semibold dark:border-kemenyan-400">
      <span class="h-2.5 w-2.5 rounded-full" style={{ background: cladeVar(clade) }} />
      {tr(lang, clade)}
    </span>
  );
}

export function Plate({ ghost, size = 40, class: cls = "" }: { ghost: Ghost; size?: number; class?: string }) {
  return (
    <img
      src={plateUrl(ghost.id)}
      alt=""
      width={size}
      height={size}
      loading="lazy"
      decoding="async"
      class={`shrink-0 rounded-full ${cls}`}
    />
  );
}

function Field({ label, value }: { label: string; value: string | null }) {
  if (!value) return null;
  return (
    <div>
      <dt class="muted text-xs font-semibold uppercase tracking-wider">{label}</dt>
      <dd class="mt-0.5 text-sm leading-relaxed">{value}</dd>
    </div>
  );
}

export default function GhostCard({
  ghost,
  lang,
  onSelect,
  compact = false,
}: {
  ghost: Ghost;
  lang: Lang;
  onSelect?: (id: string) => void;
  compact?: boolean;
}) {
  const t = useT(lang);
  const traits = presentTraits(lang, ghost);
  const relatives = ghost.relatives.map((id) => byId.get(id)!).filter(Boolean);
  return (
    <article class="glass p-5" aria-label={t("cardOf", ghost.name)}>
      <div class="flex items-start gap-4">
        <img
          src={plateUrl(ghost.id)}
          alt={t("drawnAs", ghost.name, tr(lang, ghost.morphology))}
          width={compact ? 96 : 128}
          height={compact ? 96 : 128}
          class="shrink-0 animate-drift rounded-full shadow-lg shadow-malam-950/20"
        />
        <div class="min-w-0">
          <h2 class="font-serif text-2xl font-semibold leading-tight tracking-tight">{ghost.name}</h2>
          <p class="muted mt-0.5 text-sm">
            {tr(lang, ghost.region)}
            {ghost.culture ? ` · ${tr(lang, ghost.culture)}` : ""}
          </p>
          <div class="mt-2 flex flex-wrap items-center gap-2">
            <CladePill clade={ghost.clade} lang={lang} />
            {ghost.outgroup && (
              <span class="rounded-full bg-malam-100 px-2.5 py-0.5 text-xs font-semibold text-malam-800 dark:bg-malam-800 dark:text-malam-100">
                {t("outgroup")}
              </span>
            )}
          </div>
          <div class="mt-2">
            <DangerMeter level={ghost.danger} lang={lang} />
          </div>
        </div>
      </div>

      <dl class="mt-4 grid gap-3">
        <Field label={t("form")} value={tr(lang, ghost.morphology)} />
        <Field label={t("origin")} value={tr(lang, ghost.origin)} />
        <Field label={t("behavior")} value={tr(lang, ghost.behavior)} />
        <Field label={t("deterrents")} value={tr(lang, ghost.deterrents)} />
        <Field label={t("diet")} value={tr(lang, ghost.diet)} />
      </dl>

      <div class="mt-4">
        <p class="muted text-xs font-semibold uppercase tracking-wider">{t("codedTraits")}</p>
        <div class="mt-1.5 flex flex-wrap gap-1.5">
          <span class="rounded-full bg-kafan-200 px-2 py-0.5 text-xs dark:bg-malam-800">{sexLabel(lang, ghost)}</span>
          {traits.map((x) => (
            <span key={x} class="rounded-full bg-kafan-200 px-2 py-0.5 text-xs dark:bg-malam-800">
              {x}
            </span>
          ))}
        </div>
        <p class="muted mt-2 text-xs">
          {ghost.coding !== "source" && <span class="mr-1 text-darah-700 dark:text-darah-300">◆</span>}
          {codingLabel(lang, ghost.coding)}.
          {ghost.twins.length > 0 && t("twinsCard", ghost.twins.map((x) => byId.get(x)?.name).join(", "))}
        </p>
      </div>

      {!compact && (
        <div class="mt-4">
          <p class="muted text-xs font-semibold uppercase tracking-wider">{t("nearest")}</p>
          <ul class="mt-2 flex flex-wrap gap-2">
            {relatives.map((r) => (
              <li key={r.id}>
                <button
                  type="button"
                  onClick={() => onSelect?.(r.id)}
                  class="control flex min-h-[28px] items-center gap-1.5 py-0.5 pl-0.5 pr-2.5 text-xs transition hover:bg-kafan-200 dark:hover:bg-malam-800"
                >
                  <Plate ghost={r} size={22} />
                  {r.name}
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}

      <a
        href={localePath(lang, `/ghosts/${ghost.id}`)}
        class="accent mt-4 inline-flex items-center gap-1 text-sm font-semibold underline-offset-4 hover:underline"
      >
        {t("fullPage")} <span aria-hidden="true">→</span>
      </a>
    </article>
  );
}
