"use client";
// Hindi-first driver PWA: today's stops, Start route, auto 'Spray logged'. No typing anywhere.
import { Check, Navigation, Play } from "lucide-react";
import { useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { HawaMap } from "@/components/map/HawaMap";
import { Skeleton } from "@/components/ui/Skeleton";
import { useDriverRoute } from "@/hooks/useConsoleData";

const Stop = ({ n, hi, en, time, active, strong }: { n: number; hi: string; en?: string; time: string; active?: boolean; strong?: boolean }) => (
  <div className={`flex items-center gap-3.5 rounded-xl bg-white p-3.5 ${strong ? "border-2 border-ink" : "border border-line"}`}>
    <span className={`grid size-14 flex-none place-items-center rounded-[10px] font-mono text-[28px] font-semibold ${active ? "bg-ink text-paper" : "bg-line text-ink"}`}>{n}</span>
    <div className="min-w-0 flex-1">
      <div className="font-deva text-[19px] font-semibold leading-[1.3]">{hi}</div>
      {en && <div className="text-[13px] text-muted-2">{en}</div>}
      <div className="mt-0.5 font-mono text-sm font-medium">{time}</div>
    </div>
  </div>
);

function DriverRoute() {
  const asset = useSearchParams().get("asset") ?? "T-12";
  const q = useDriverRoute(asset);
  const [started, setStarted] = useState(false);
  const r = q.data;

  if (!r) return <div className="flex flex-col gap-3 p-5"><Skeleton className="h-8 w-1/2" /><Skeleton className="h-40 w-full rounded-xl" /></div>;

  const next = r.stops.find((s) => s.status === "todo");
  const target = next ?? r.stops.find((s) => s.status === "active");
  const mapsHref = target ? `https://www.google.com/maps/dir/?api=1&travelmode=driving&destination=${encodeURIComponent(`${target.placeEn}, Delhi`)}` : undefined;

  return (
    <div className="relative flex flex-1 flex-col">
      <div className="flex flex-col gap-1.5 px-5 pb-4 pt-5">
        <div className="flex items-center gap-2">
          <span className="rounded-md bg-ink px-2 py-[3px] font-mono text-[13px] font-semibold text-paper">{r.asset}</span>
          <span className="font-deva text-[13px] text-muted-3">{started ? `स्टॉप 1 / ${r.stops.length}` : r.assetLabelHi}</span>
          {started && <><div className="flex-1" /><span className="text-[13px] text-muted-2">रूट चालू</span></>}
        </div>
        {!started && (
          <>
            <div className="font-deva text-[30px] font-bold leading-[1.2] tracking-[-.01em]">आज का रूट</div>
            <div className="text-sm text-muted-2">Today&apos;s route · {r.dateLabel} · <span className="font-mono">{r.window}</span></div>
          </>
        )}
      </div>

      {!started ? (
        <>
          <div className="relative mx-5 h-[150px] overflow-hidden rounded-xl border border-line">
            <HawaMap mode="plan" hour={42} layers={["hex", "trucks"]} labels="none" center={[77.305, 28.638]} zoom={12.4} interactive={false} assets={[r.asset]} />
          </div>
          <div className="flex flex-1 flex-col gap-2.5 px-5 pt-4">
            {r.stops.map((s) => <Stop key={s.n} n={s.n} hi={s.placeHi} en={`${s.placeEn} · ${s.actionEn}`} time={`${s.from}–${s.to}`} active={s.status === "active"} />)}
          </div>
          <div className="sticky bottom-0 flex flex-col gap-2.5 bg-gradient-to-b from-paper/0 to-paper to-25% px-5 pb-7 pt-4">
            <div className="text-center font-deva text-[13px] text-muted-3">छिड़काव HawaTag अपने-आप दर्ज करेगा · Spray is logged automatically</div>
            <button onClick={() => setStarted(true)} className="flex h-[68px] items-center justify-center gap-3 rounded-[14px] bg-teal text-white shadow-[0_6px_16px_rgba(15,118,110,.3)] active:scale-[.98]">
              <Play size={22} strokeWidth={2.5} />
              <span className="flex flex-col items-start"><span className="font-deva text-[22px] font-bold leading-[1.1]">रूट शुरू करें</span><span className="text-[13px] font-medium opacity-90">Start route</span></span>
            </button>
          </div>
        </>
      ) : (
        <>
          <div className="mx-5 flex flex-col items-center gap-2.5 rounded-2xl bg-teal px-5 py-6 text-center text-white">
            <span className="grid size-[72px] place-items-center rounded-full bg-white text-teal"><Check size={40} strokeWidth={3} /></span>
            <div className="font-deva text-[28px] font-bold leading-[1.2]">छिड़काव दर्ज ✓</div>
            <div className="text-[17px] font-semibold">Spray logged</div>
            <div className="font-deva text-sm leading-normal opacity-95">{r.stops[0]?.placeHi} · HawaTag ने अपने-आप दर्ज किया</div>
          </div>
          {r.lastSpray && (
            <div className="mx-5 mt-3 grid grid-cols-3 gap-px overflow-hidden rounded-xl border border-line bg-line">
              {[["पानी", r.lastSpray.litres.toLocaleString("en-IN"), " L"], ["पंप चालू", r.lastSpray.pumpMin, " min"], ["पंप", r.lastSpray.pumpOn ? "ON" : "OFF", ""]].map(([k, v, u]) => (
                <div key={k as string} className="flex flex-col gap-0.5 bg-white p-3"><span className="font-deva text-xs text-muted-2">{k}</span><span className="font-mono text-xl font-semibold">{v}<span className="text-xs text-muted-2">{u}</span></span></div>
              ))}
            </div>
          )}
          {next && (
            <>
              <div className="mx-5 mt-5 text-[13px] text-muted-2">अगला स्टॉप · Next</div>
              <div className="mx-5 mt-2"><Stop n={next.n} hi={next.placeHi} time={`${next.from} · 2.4 km`} active strong /></div>
            </>
          )}
          <div className="flex-1" />
          <div className="px-5 pb-7 pt-4">
            <a href={mapsHref} target="_blank" rel="noopener noreferrer" aria-disabled={!mapsHref} className={`flex h-[68px] w-full items-center justify-center gap-3 rounded-[14px] bg-ink text-paper no-underline ${mapsHref ? "" : "pointer-events-none opacity-50"}`}>
              <Navigation size={22} strokeWidth={2.5} />
              <span className="flex flex-col items-start"><span className="font-deva text-[22px] font-bold leading-[1.1]">रास्ता दिखाएँ</span><span className="text-[13px] font-medium opacity-80">Navigate to stop {target?.n ?? ""}</span></span>
            </a>
          </div>
        </>
      )}
    </div>
  );
}

export default function DriverRoutePage() {
  return <Suspense><DriverRoute /></Suspense>;
}
