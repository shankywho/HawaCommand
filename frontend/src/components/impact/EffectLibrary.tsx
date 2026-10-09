import type { EffectLibraryRow } from "@hawa/contracts";
import { CAUSE_ICON } from "@/components/ui/icons";
import { fmtPct } from "@/lib/format";

const COLS = "grid min-w-[640px] grid-cols-[110px_120px_minmax(0,1fr)_120px_72px_40px] gap-x-3 px-4 py-2.5";

export function EffectLibrary({ rows }: { rows: EffectLibraryRow[] }) {
  return (
    <div className="card overflow-auto">
      <div className="flex flex-wrap items-baseline gap-3 border-b border-line px-4 py-3">
        <span className="text-[15px] font-semibold">Effectiveness library</span>
        <span className="text-[13.5px] text-muted">Typical effect of each action by cause and weather. Updates the planner nightly.</span>
      </div>
      <div className={`${COLS} border-b border-line text-[13px] font-medium text-muted`}>
        <span>Action</span><span>Cause</span><span>Weather</span><span>Typical effect</span><span className="text-right">Duration</span><span className="text-right">n</span>
      </div>
      {rows.map((b) => {
        const Icon = CAUSE_ICON[b.cause];
        return (
          <div key={`${b.action}-${b.cause}-${b.weather}`} className={`${COLS} items-center border-b border-line-soft text-sm`}>
            <span>{b.action}</span>
            <span className="flex items-center gap-1.5"><Icon size={13} />{b.cause}</span>
            <span className="text-muted">{b.weather}</span>
            <span className="font-mono text-[13px] font-medium">
              {b.effectPct === 0 ? "~0%" : fmtPct(b.effectPct)}{" "}
              <span className="font-normal text-muted">[{fmtPct(b.ci[0]).replace("+", "")}, {b.ci[1] > 0 ? "+" : ""}{fmtPct(b.ci[1]).replace("+", "")}]</span>
            </span>
            <span className="text-right font-mono text-[13px] text-muted">{b.durationMin === null ? "—" : b.durationMin >= 120 ? `${b.durationMin / 60} h` : `${b.durationMin} min`}</span>
            <span className="text-right font-mono text-[13px] text-muted">{b.n}</span>
          </div>
        );
      })}
    </div>
  );
}
