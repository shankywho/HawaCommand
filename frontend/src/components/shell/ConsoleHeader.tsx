"use client";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { ChevronsUpDown, MapPin, Search } from "lucide-react";
import { AqiChip } from "@/components/ui/AqiChip";
import { Logo } from "@/components/ui/Logo";
import { useForecast } from "@/hooks/useConsoleData";
import { atHour } from "@/components/map/layers";
import { useWardHotspots } from "@/hooks/useHotspots";
import { clock, dayTime, now } from "@/lib/time";
import { ALL_WARDS, useConsole } from "@/stores/console";
import { wardLabel } from "@/lib/format";

export function ConsoleHeader() {
  const { ward, hour, setPalette, setWard } = useConsole();
  const [wardsOpen, setWardsOpen] = useState(false);
  const wardRef = useRef<HTMLDivElement>(null);
  const hs = useWardHotspots(0).data;
  const fc = useForecast(ward).data;
  const wardOptions = Array.from(new Set([ALL_WARDS, ward, ...(fc?.wards.map((w) => w.ward) ?? [])]));
  useEffect(() => {
    if (!wardsOpen) return;
    const close = (e: Event) => {
      if (e.type === "keydown" ? (e as KeyboardEvent).key === "Escape" : !wardRef.current?.contains(e.target as Node)) setWardsOpen(false);
    };
    document.addEventListener("mousedown", close);
    document.addEventListener("keydown", close);
    return () => {
      document.removeEventListener("mousedown", close);
      document.removeEventListener("keydown", close);
    };
  }, [wardsOpen]);
  const shown = hs ? atHour(hs.items, hour) : [];
  const peak = shown.length ? Math.round(Math.max(...shown.map((h) => h.pm25))) : undefined;
  return (
    <header className="col-span-2 row-start-1 flex min-w-0 items-center gap-3.5 border-b border-line bg-white px-4">
      <Link href="/" title="Back to the landing page" className="!text-ink no-underline"><Logo /></Link>
      <div ref={wardRef} className="relative flex-none">
        <button onClick={() => setWardsOpen(!wardsOpen)} aria-haspopup="listbox" aria-expanded={wardsOpen} className="btn btn-md btn-quiet gap-2 px-2.5 font-medium">
          <MapPin size={14} />
          {wardLabel(ward)}
          {fc && fc.wards.length > 1 && <span className="hidden font-normal text-muted min-[1100px]:inline">+ {fc.wards.length - 1} wards</span>}
          <ChevronsUpDown size={13} />
        </button>
        {wardsOpen && (
          <ul role="listbox" aria-label="Ward" className="absolute left-0 top-full z-40 m-0 mt-1 min-w-[200px] list-none rounded-lg border border-line bg-white p-1 shadow-modal">
            {wardOptions.map((w) => (
              <li key={w}>
                <button role="option" aria-selected={w === ward} onClick={() => { setWard(w); setWardsOpen(false); }} className={`flex w-full items-center rounded-md px-2.5 py-2 text-left text-sm hover:bg-hover ${w === ward ? "bg-hover font-medium" : ""}`}>
                  {wardLabel(w)}
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
      <div className="flex-1" />
      {peak !== undefined && <AqiChip place={ward} value={peak} kind="pm25" title={`Highest hotspot PM2.5 ${hour > 0 ? `at +${hour} h` : "now"}${fc ? ` · GRAP Stage ${fc.grap.stage}: ${fc.grap.headline}` : ""}`} />}
      <button onClick={() => setPalette(true)} className="flex h-8 min-w-[120px] flex-[0_1_220px] cursor-pointer items-center gap-2 whitespace-nowrap rounded-md border border-line bg-paper pl-2.5 pr-2 text-[13.5px] text-muted hover:bg-hover">
        <Search size={14} className="flex-none" />
        <span className="min-w-0 flex-1 text-left">Search</span>
        <span className="flex-none rounded border border-line bg-white px-[5px] text-xs">⌘K</span>
      </button>
      <span title={hs ? `Hotspots updated ${clock(hs.asOf)}` : "Waiting for data"} className="flex-none cursor-help whitespace-nowrap font-mono text-[13px] font-medium">
        {dayTime(now())}
      </span>
    </header>
  );
}
