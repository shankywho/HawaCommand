import type { Alert } from "@hawa/contracts";
import { Camera, HardHat, School, Users, type LucideIcon } from "lucide-react";
import { dayTime } from "@/lib/time";

const ICON: Record<Alert["audience"], LucideIcon> = { School, Citizens: Users, "Citizen Eyes": Camera, Workers: HardHat, Drivers: Users };
const LANG: Record<Alert["lang"], string> = { hi: "HI", en: "EN", "hi+en": "HI+EN" };
const COLS = "grid min-w-[620px] grid-cols-[76px_minmax(0,1fr)_128px_88px_52px] gap-x-3 px-4";

export function AlertsTable({ items, selected, onPick }: { items: Alert[]; selected: string; onPick: (id: string) => void }) {
  return (
    <div className="card overflow-auto">
      <div className={`${COLS} border-b border-line py-2.5 text-[13px] font-medium text-muted`}>
        <span>Sent</span><span>Recipient and message</span><span>Channel</span><span>Delivered</span><span className="text-right">Lead time</span>
      </div>
      {items.map((a) => {
        const Icon = ICON[a.audience];
        return (
          <button key={a.id} onClick={() => onPick(a.id)} className={`${COLS} w-full items-center border-b border-line-soft py-[11px] text-left text-sm hover:bg-hover ${selected === a.id ? "row-selected" : ""}`}>
            <span className="font-mono text-[13px] text-muted">{dayTime(a.sentAt)}</span>
            <span className="flex min-w-0 items-start gap-[9px]">
              <span title={a.audience} className="mt-0.5 flex flex-none text-muted"><Icon size={15} /></span>
              <span className="flex min-w-0 flex-col gap-0.5"><span className="text-pretty font-medium">{a.target}</span><span className="text-pretty text-[13.5px] text-muted">{a.message}</span></span>
            </span>
            <span className="flex flex-wrap items-center gap-1.5"><span>{a.channel}</span><span title="Language" className="rounded bg-hover px-1.5 py-px text-[11.5px] font-medium">{LANG[a.lang]}</span></span>
            <span className="font-mono text-[13px] text-muted">{a.delivered}</span>
            <span className="text-right font-mono text-[13px] text-muted">{a.leadTimeH === null ? "—" : `${a.leadTimeH} h`}</span>
          </button>
        );
      })}
    </div>
  );
}
