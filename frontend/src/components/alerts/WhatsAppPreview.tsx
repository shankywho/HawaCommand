import type { Alert } from "@hawa/contracts";
import { clock, dayTime } from "@/lib/time";

export function WhatsAppPreview({ a }: { a: Alert }) {
  const t = clock(a.sentAt);
  return (
    <>
      <div className="panel-head flex flex-col gap-[3px]">
        <span className="text-[13.5px] text-muted">{a.channel} preview</span>
        <span className="text-pretty text-base font-semibold leading-[1.3]">{a.target}</span>
        <span className="text-[13.5px] text-muted">Drafted by the {a.draftedBy} agent</span>
      </div>
      <div className="flex flex-1 flex-col gap-2.5 bg-whatsapp-bg p-4">
        <div className="self-center rounded-md bg-white px-[9px] py-[3px] text-[12.5px]">{dayTime(a.sentAt)}</div>
        {a.messageHi && (
          <div className="flex max-w-[92%] flex-col gap-1.5 self-start rounded-[2px_10px_10px_10px] bg-white px-3 py-2.5 shadow-[0_1px_1px_rgba(11,18,21,.08)]">
            <span className="text-[13px] font-semibold">HawaCommand · Delhi air alerts</span>
            <span className="font-deva text-[15px] leading-[1.6]">{a.messageHi}</span>
            <span className="self-end text-xs text-muted">{t}</span>
          </div>
        )}
        <div className="flex max-w-[92%] flex-col gap-1.5 self-start rounded-[10px] bg-white px-3 py-2.5 shadow-[0_1px_1px_rgba(11,18,21,.08)]">
          <span className="text-[15px] leading-[1.55]">{a.message}</span>
          <span className="self-end text-xs text-muted">{t}</span>
        </div>
      </div>
      <div className="flex flex-col border-t border-line px-[18px] py-2.5 text-sm">
        <div className="fact-row !py-[7px]"><span className="text-muted">Lead time before spike</span><span>{a.leadTimeH === null ? "—" : `${a.leadTimeH} h`}</span></div>
        <div className="fact-row !py-[7px]"><span className="text-muted">Indoor vs outdoor, 08:00</span><span>Awaiting indoor sensor</span></div>
      </div>
    </>
  );
}
