// ranked list with verb (Send inspector / sprinkler / Alert schools)
import type { Hotspot } from "@hawa/contracts";
import { BandSwatch } from "@/components/ui/AqiChip";
import { CAUSE_ICON } from "@/components/ui/icons";
import { CAUSE_VERB } from "@/lib/format";

export function HotspotList({ items, thresholdUgm3, hourShort, onPick }: {
  items: Hotspot[]; thresholdUgm3: number; hourShort: string; onPick: (cellId: string) => void;
}) {
  const sorted = [...items].sort((a, b) => b.pm25 - a.pm25);
  return (
    <>
      <div className="panel-head flex flex-wrap items-baseline justify-between gap-2.5">
        <span className="text-base font-semibold">Hotspots</span>
        <span className="text-[13px] text-muted">PM2.5 µg/m³ · {hourShort}</span>
      </div>
      {sorted.map((h, i) => {
        const Icon = CAUSE_ICON[h.cause];
        const watch = h.pm25 < thresholdUgm3;
        return (
          <button key={h.cellId} onClick={() => onPick(h.cellId)} style={{ animationDelay: `${Math.min(i, 14) * 38}ms` }} className="grid animate-[rowIn_.45s_cubic-bezier(.2,.7,.2,1)_both] grid-cols-[minmax(0,1fr)_auto] items-center gap-3 border-b border-line-soft px-[18px] py-[11px] text-left transition-[background,padding] duration-200 hover:bg-hover hover:pl-[24px]">
            <span className="flex min-w-0 flex-col gap-[3px]">
              <span className="text-[14.5px] font-medium">{h.place}</span>
              <span className="flex items-center gap-1.5 text-[13.5px] text-muted">
                <span title={h.cause}><Icon size={14} /></span>
                {CAUSE_VERB[h.cause]}
              </span>
            </span>
            <span className="flex items-center gap-[7px] whitespace-nowrap font-mono text-sm font-medium">
              {watch && <span className="rounded border border-line px-1.5 py-px font-sans text-xs font-medium text-muted">Watch</span>}
              <BandSwatch pm25={h.pm25} muted={watch} />
              {h.pm25}
            </span>
          </button>
        );
      })}
    </>
  );
}
