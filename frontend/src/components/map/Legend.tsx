import { BAND_COLORS_DARK, BANDS, PM25_BREAKPOINTS } from "@hawa/contracts";

// bottom-left legend: PM2.5 category gradient (same six bands and colours as the map overlay), route and school keys
export function Legend({ thresholdUgm3 }: { thresholdUgm3: number }) {
  const gradient = `linear-gradient(90deg, ${BAND_COLORS_DARK.join(", ")})`;
  return (
    <div className="pointer-events-none absolute bottom-[78px] left-3.5 flex flex-wrap items-end gap-x-4 gap-y-2 text-[12.5px] font-medium [text-shadow:0_0_3px_#fff,0_0_3px_#fff,0_0_4px_#fff]">
      <div className="flex w-[232px] flex-col gap-1" title={`Highlighted above ${thresholdUgm3} µg/m³`}>
        <span className="flex justify-between"><span>PM2.5 µg/m³</span><span className="font-normal text-muted">{BANDS[0]} → {BANDS[5]}</span></span>
        <i className="block h-2 rounded-full" style={{ background: gradient }} />
        <span className="relative h-3 font-mono text-[11px] font-normal text-muted">
          {PM25_BREAKPOINTS.map((t, i) => (
            <span key={t} className="absolute -translate-x-1/2" style={{ left: `${((i + 1) / 6) * 100}%` }}>{t}</span>
          ))}
        </span>
      </div>
      <span className="flex items-center gap-1.5"><i className="w-3.5 border-t-2 border-dashed border-teal" />Route</span>
      <span className="flex items-center gap-1.5"><i className="size-2.5 rounded-sm border border-ink bg-white" />School</span>
    </div>
  );
}
