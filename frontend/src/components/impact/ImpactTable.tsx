// effect, 95% CI bar, duration, verified tick
import type { Intervention } from "@hawa/contracts";
import { BadgeCheck } from "lucide-react";
import { fmtPct } from "@/lib/format";

/** CI bars are drawn on a −40% … +10% scale; 0 sits at 80%. */
const sc = (x: number) => ((x + 40) / 50) * 100;
const COLS = "grid min-w-[640px] grid-cols-[52px_52px_minmax(0,1fr)_52px_112px_96px_60px] gap-x-2.5";

export function ImpactTable({ items, selected, onPick }: { items: Intervention[]; selected: string; onPick: (id: string) => void }) {
  return (
    <div className="card overflow-auto">
      <div className={`${COLS} items-end border-b border-line px-3.5 py-2.5 text-[13px] font-medium text-muted`}>
        <span>ID</span><span>Asset</span><span>Cell</span><span className="text-right">Effect</span><span>95% CI</span>
        <span className="relative h-4 text-xs"><span className="absolute left-0 top-0">−40%</span><span className="absolute left-[80%] top-0 -translate-x-1/2 font-medium text-ink">0</span></span>
        <span className="text-right">Duration</span>
      </div>
      {items.map((v) => {
        const im = v.impact;
        if (!im) return null;
        const verified = im.verdict === "Verified";
        return (
          <button key={v.id} onClick={() => onPick(v.id)} className={`${COLS} w-full items-center border-b border-line-soft px-3.5 py-[11px] text-left text-sm hover:bg-hover ${selected === v.id ? "row-selected" : ""}`}>
            <span className="font-mono text-[13px] text-muted">{v.id}</span>
            <span className="font-mono text-[13px] font-medium">{v.asset}</span>
            <span className="flex min-w-0 flex-col gap-0.5">
              <span className="flex flex-wrap items-center gap-1.5">
                <span className="text-pretty">{v.place}</span>
                {verified && <BadgeCheck size={15} aria-label="Verified" />}
              </span>
              <span className="text-[13px] text-muted">{v.action} · {v.cause}{verified ? "" : ` · ${im.verdict}`}</span>
            </span>
            <span className="text-right font-mono text-[13px] font-medium">{fmtPct(im.effectPct)}</span>
            <span className="whitespace-nowrap font-mono text-[13px] text-muted">{im.ciLow} to {im.ciHigh > 0 ? "+" : ""}{im.ciHigh}</span>
            <span className="relative h-2 rounded bg-line-soft">
              <i className="absolute inset-y-0 rounded bg-line-strong" style={{ left: `${sc(im.ciLow)}%`, width: `${sc(im.ciHigh) - sc(im.ciLow)}%` }} />
              <i className="absolute -top-[3px] left-[80%] h-3.5 w-px bg-muted" />
              <i className="absolute -top-[3px] -ml-px h-3.5 w-0.5 bg-ink" style={{ left: `${sc(im.effectPct)}%` }} />
            </span>
            <span className="text-right font-mono text-[13px] text-muted">{im.durationMin} min</span>
          </button>
        );
      })}
      <div className="px-3.5 py-[9px] text-[13px] text-muted">Bars show the 95% confidence interval on a −40% to +10% scale. Simulated interventions with injected effects.</div>
    </div>
  );
}
