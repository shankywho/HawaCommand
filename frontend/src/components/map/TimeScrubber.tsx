"use client";
// Now / Peak marks, past 24h to +72h
import { useEffect, useMemo, useState } from "react";
import { usePeakHour } from "@/hooks/usePeakHour";
import { addHours, dayTime, hoursAtClock, hourLabel, now } from "@/lib/time";

const pct = (h: number) => `${(((h + 24) / 96) * 100).toFixed(2)}%`;
const TICKS = Array.from({ length: 17 }, (_, i) => -24 + i * 6);

export function TimeScrubber({ hour, onChange }: { hour: number; onChange: (h: number) => void }) {
  const peak = usePeakHour();
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  const days = useMemo<[number, string][]>(
    () => [[0, "Now"], ...hoursAtClock(12, -24, 72).filter((h) => Math.abs(h) > 5).map((h): [number, string] => [h, dayTime(addHours(now(), h)).slice(0, 3)])],
    [],
  );
  const kind = hour > 0 ? "Forecast; confidence falls with distance" : hour < 0 ? "Observed replay" : "Live";
  return (
    <div className="absolute inset-x-0 bottom-0 border-t border-line bg-white/95 px-4 py-2">
      <div className="mb-1 flex items-center gap-2.5">
        <span className="whitespace-nowrap text-[13.5px] font-medium">{hourLabel(hour)}</span>
        <span className="whitespace-nowrap text-[13px] text-muted">{kind}</span>
        <div className="flex-1" />
        <button onClick={() => onChange(0)} className="h-6 rounded-[5px] border border-line bg-white px-[9px] text-[12.5px] hover:bg-hover">Now</button>
        <button onClick={() => onChange(peak)} className="h-6 rounded-[5px] border border-line bg-white px-[9px] text-[12.5px] hover:bg-hover">{mounted ? `Peak ${dayTime(addHours(now(), peak))}` : "Peak"}</button>
      </div>
      <div className="relative h-[30px]">
        {TICKS.map((h) => (
          <i key={h} className="absolute top-1 w-px bg-line-strong" style={{ left: pct(h), height: h % 24 === 10 ? 10 : 5 }} />
        ))}
        <div className="absolute left-0 top-2.5 h-0.5 w-1/4 bg-line-strong" />
        <div className="absolute left-1/4 right-0 top-2.5 h-0.5 bg-[repeating-linear-gradient(90deg,#CFCAC0_0_4px,transparent_4px_8px)]" />
        <div className="absolute left-1/4 top-0.5 -ml-px h-[18px] w-0.5 bg-ink" />
        <div className="pointer-events-none absolute top-[3px] -ml-2 size-4 rounded-full border-[3px] border-white bg-teal shadow-[0_0_0_1px_#0F766E] transition-[left] duration-150" style={{ left: pct(hour) }} />
        {mounted && days.map(([h, l]) => (
          <span key={l} className="absolute top-[17px] -translate-x-1/2 whitespace-nowrap text-xs" style={{ left: pct(h), color: h === 0 ? "#0B1215" : "#4A555B" }}>{l}</span>
        ))}
        <input
          type="range" min={-24} max={72} step={1} value={hour}
          onChange={(e) => onChange(Number(e.target.value))}
          aria-label="Time scrubber, past 24 hours to 72 hour forecast"
          className="absolute inset-0 m-0 w-full cursor-pointer opacity-0"
        />
      </div>
    </div>
  );
}
