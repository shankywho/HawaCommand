// selected asset + live HawaTag state
import type { Asset } from "@hawa/contracts";
import { fmtInt } from "@/lib/format";

const toPct = (hhmm: string) => {
  const [h, m] = hhmm.split(":").map(Number);
  return (((h! * 60 + m!) - 5.5 * 60) / (6 * 60)) * 100;
};

export function AssetPanel({ a }: { a: Asset }) {
  const t = a.tag;
  const on = t?.pumpOn ?? false;
  const tiles: [string, React.ReactNode, string][] = [
    ["Flow", on ? t!.flowLpm : 0, " L/min"],
    ["This run", fmtInt(t?.litresThisRun ?? 0), ` / ${fmtInt(t?.tankLitres ?? 1850)} L`],
    ["PM10 before", t?.pm10Before ?? "—", " µg/m³"],
    ["PM10 now", t?.pm10Now ?? "—", " µg/m³"],
  ];
  return (
    <>
      <div className="flex flex-col gap-1.5 border-b border-line px-[18px] py-4">
        <div className="flex items-center gap-2">
          <span className="text-[13.5px] text-muted">{a.label}</span>
          <div className="flex-1" />
          {a.simulated && <span title="Simulated in the exact firmware packet format" className="inline-flex h-[22px] cursor-help items-center whitespace-nowrap rounded-full border border-dashed border-muted px-2 text-xs text-muted">Simulated</span>}
        </div>
        <div className="text-[22px] font-semibold tracking-[-.02em]">{a.id}</div>
        <div className="text-[14.5px]">{a.task}</div>
      </div>
      {t ? (
        <>
          <div className="flex flex-col gap-2.5 border-b border-line px-[18px] py-3.5">
            <div className="flex items-center gap-2">
              <span title={`${t.tagId} · firmware ${t.fw}`} className="cursor-help text-sm font-medium">HawaTag</span>
              <div className="flex-1" />
              <span className="inline-flex h-6 items-center gap-1.5 whitespace-nowrap rounded-[5px] px-[9px] text-[12.5px] font-semibold" style={{ background: on ? "#0B1215" : "#F4F2ED", color: on ? "#FFFFFF" : "#0B1215" }}>
                <i className="size-1.5 rounded-full bg-current" />{on ? "Pump on" : "Pump off"}
              </span>
            </div>
            <div className="grid grid-cols-2 gap-px overflow-hidden rounded-lg border border-line bg-line">
              {tiles.map(([k, v, u]) => (
                <div key={k} className="flex flex-col gap-0.5 bg-white px-3 py-2.5">
                  <span className="text-[13px] text-muted">{k}</span>
                  <span className="text-lg font-semibold">{v}<span className="text-[12.5px] font-normal text-muted">{u}</span></span>
                </div>
              ))}
            </div>
            <div className="flex flex-col gap-1.5">
              <span className="text-[13px] text-muted">Spraying today</span>
              <div className="relative h-[22px] overflow-hidden rounded border border-line bg-paper">
                {t.sprayWindows.map((w, i) => (
                  <i key={i} className="absolute inset-y-1 rounded-sm" style={{ left: `${toPct(w.start)}%`, width: `${toPct(w.end) - toPct(w.start)}%`, background: i === t.sprayWindows.length - 1 ? "#4A555B" : "#0B1215" }} />
                ))}
              </div>
              <div className="flex justify-between text-xs text-muted"><span>05:30</span><span>07:30</span><span>09:30</span><span>11:30</span></div>
            </div>
          </div>
          <div className="flex flex-col px-[18px] py-2.5 text-sm">
            {[
              ["Tamper seal", t.tamperIntact ? "Intact" : "Broken", undefined],
              ["4G signal", t.signalDbm > -90 ? "Good" : "Weak", `${t.signalDbm} dBm`],
              ["Trust score", t.trust >= 0.8 ? "High" : "Medium", t.trust.toFixed(2)],
              ["Last packet", "6 s ago", `Sequence ${t.lastSeq}`],
            ].map(([k, v, title]) => (
              <div key={k} className="fact-row !py-[7px]"><span className="text-muted">{k}</span><span title={title} className={title ? "cursor-help" : ""}>{v}</span></div>
            ))}
          </div>
        </>
      ) : (
        <div className="px-[18px] py-3.5 text-sm text-muted">No HawaTag fitted to this asset.</div>
      )}
    </>
  );
}
