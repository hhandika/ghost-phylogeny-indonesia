/** Detail card for one ghost, shared by the Atlas, Lantern, and Bestiary designs. */
import { byId, cladeVar, CODING_LABEL, DANGER, plateUrl, presentTraits, sexLabel, withBase, type Ghost } from "../utils/data";

export function DangerMeter({ level }: { level: number }) {
  return (
    <span class="inline-flex items-center gap-1" title={`Danger ${level} of 5: ${DANGER[level]}`}>
      {[1, 2, 3, 4, 5].map((i) => (
        <span
          key={i}
          class={`h-2 w-2 rotate-45 ${i <= level ? "bg-darah-600 dark:bg-darah-400" : "bg-kafan-300 dark:bg-malam-700"}`}
        />
      ))}
      <span class="ml-1 text-xs text-kafan-700 dark:text-kemenyan-300">{DANGER[level]}</span>
    </span>
  );
}

export function CladePill({ clade }: { clade: string }) {
  return (
    <span class="inline-flex items-center gap-1.5 rounded-full border border-kafan-300 px-2.5 py-0.5 text-xs font-semibold dark:border-malam-700">
      <span class="h-2.5 w-2.5 rounded-full" style={{ background: cladeVar(clade) }} />
      {clade}
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
      <dt class="text-xs font-semibold uppercase tracking-wider text-kafan-600 dark:text-kemenyan-400">{label}</dt>
      <dd class="mt-0.5 text-sm leading-relaxed">{value}</dd>
    </div>
  );
}

export default function GhostCard({
  ghost,
  onSelect,
  compact = false,
}: {
  ghost: Ghost;
  onSelect?: (id: string) => void;
  compact?: boolean;
}) {
  const traits = presentTraits(ghost);
  const relatives = ghost.relatives.map((id) => byId.get(id)!).filter(Boolean);
  return (
    <article class="rounded-3xl border border-kafan-300 bg-kafan-50/90 p-5 shadow-sm backdrop-blur dark:border-malam-700 dark:bg-malam-900/90">
      <div class="flex items-start gap-4">
        <img
          src={plateUrl(ghost.id)}
          alt={`${ghost.name}, drawn as ${ghost.morphology.toLowerCase()}`}
          width={compact ? 96 : 128}
          height={compact ? 96 : 128}
          class="shrink-0 animate-drift rounded-full shadow-lg shadow-malam-950/20"
        />
        <div class="min-w-0">
          <h2 class="font-serif text-2xl font-semibold leading-tight tracking-tight">{ghost.name}</h2>
          <p class="mt-0.5 text-sm text-kafan-700 dark:text-kemenyan-300">
            {ghost.region}
            {ghost.culture ? ` · ${ghost.culture}` : ""}
          </p>
          <div class="mt-2 flex flex-wrap items-center gap-2">
            <CladePill clade={ghost.clade} />
            {ghost.outgroup && (
              <span class="rounded-full bg-malam-100 px-2.5 py-0.5 text-xs font-semibold text-malam-800 dark:bg-malam-800 dark:text-malam-100">
                Outgroup
              </span>
            )}
          </div>
          <div class="mt-2">
            <DangerMeter level={ghost.danger} />
          </div>
        </div>
      </div>

      <dl class="mt-4 grid gap-3">
        <Field label="Form" value={ghost.morphology} />
        <Field label="Origin" value={ghost.origin} />
        <Field label="Behaviour" value={ghost.behavior} />
        <Field label="Deterrents" value={ghost.deterrents} />
        <Field label="Diet" value={ghost.diet} />
      </dl>

      <div class="mt-4">
        <p class="text-xs font-semibold uppercase tracking-wider text-kafan-600 dark:text-kemenyan-400">Coded traits</p>
        <div class="mt-1.5 flex flex-wrap gap-1.5">
          <span class="rounded-full bg-kafan-200 px-2 py-0.5 text-xs dark:bg-malam-800">{sexLabel(ghost)}</span>
          {traits.map((t) => (
            <span key={t} class="rounded-full bg-kafan-200 px-2 py-0.5 text-xs dark:bg-malam-800">
              {t}
            </span>
          ))}
        </div>
        <p class="mt-2 text-xs text-kafan-700 dark:text-kemenyan-300">
          {ghost.coding !== "source" && <span class="mr-1 text-darah-700 dark:text-darah-300">◆</span>}
          {CODING_LABEL[ghost.coding]}.
          {ghost.twins.length > 0 &&
            ` Shares an identical row with ${ghost.twins.map((t) => byId.get(t)?.name).join(", ")}, so the tree cannot separate them.`}
        </p>
      </div>

      {!compact && (
        <div class="mt-4">
          <p class="text-xs font-semibold uppercase tracking-wider text-kafan-600 dark:text-kemenyan-400">Nearest on the tree</p>
          <ul class="mt-2 flex flex-wrap gap-2">
            {relatives.map((r) => (
              <li key={r.id}>
                <button
                  type="button"
                  onClick={() => onSelect?.(r.id)}
                  class="flex items-center gap-1.5 rounded-full border border-kafan-300 py-0.5 pl-0.5 pr-2.5 text-xs transition hover:border-darah-500 hover:bg-kafan-200 dark:border-malam-700 dark:hover:border-prada-400 dark:hover:bg-malam-800"
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
        href={withBase(`/ghosts/${ghost.id}`)}
        class="mt-4 inline-flex items-center gap-1 text-sm font-semibold text-darah-700 underline-offset-4 hover:underline dark:text-prada-300"
      >
        Full specimen page <span aria-hidden="true">→</span>
      </a>
    </article>
  );
}
