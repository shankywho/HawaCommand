import type { Asset } from "@hawa/contracts";
import { ago } from "@/lib/format";
import { now } from "@/lib/time";

const DOT: Record<Asset["status"], string> = {
  Spraying: "#0B1215", "En route": "#4A555B", Done: "#CFCAC0", "On site": "#4A555B", Refilling: "#CFCAC0", Offline: "#C02A2A", Idle: "#CFCAC0",
};
const COLS = "grid min-w-[780px] grid-cols-[64px_128px_minmax(0,1fr)_96px_132px_72px] gap-x-3 px-4 py-2.5";

export function FleetTable({ items, selected, onPick }: { items: Asset[]; selected: string; onPick: (id: string) => void }) {
  return (
    <div className="max-h-[42%] flex-none overflow-auto border-t border-line bg-white">
      <div className={`${COLS} sticky top-0 border-b border-line bg-white text-[13px] font-medium text-muted`}>
        <span>Asset</span><span>Type</span><span>Current task</span><span>Status</span><span>HawaTag</span><span className="text-right">Last ping</span>
      </div>
      {items.map((f) => (
        <button key={f.id} onClick={() => onPick(f.id)} className={`${COLS} w-full items-center border-b border-line-soft text-left text-sm hover:bg-hover ${selected === f.id ? "row-selected" : ""}`}>
          <span className="font-mono text-[13px] font-medium">{f.id}</span>
          <span className="whitespace-nowrap text-muted">{f.label}</span>
          <span title={f.task} className="truncate">{f.task}</span>
          <span className="flex items-center gap-[7px]"><i className="size-[7px] rounded-full" style={{ background: DOT[f.status] }} />{f.status}</span>
          <span className="text-[13px] text-muted">{f.tagSummary}</span>
          <span className="text-right font-mono text-[13px] text-muted">{ago(f.lastPingAt, now())}</span>
        </button>
      ))}
    </div>
  );
}
