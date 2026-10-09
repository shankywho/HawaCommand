"use client";
// SCREEN B Forecast: GRAP line + ward table
import { GitPullRequest, TriangleAlert } from "lucide-react";
import Link from "next/link";
import { useEffect, useState } from "react";
import { ForecastChart } from "@/components/charts/ForecastChart";
import { HawaMap } from "@/components/map/HawaMap";
import { useMapStations } from "@/components/map/useMapStations";
import { Legend } from "@/components/map/Legend";
import { TimeScrubber } from "@/components/map/TimeScrubber";
import { Screen } from "@/components/shell/Screen";
import { QueryError } from "@/components/ui/Skeleton";
import { useForecast } from "@/hooks/useConsoleData";
import { bandColor, pm25BandIndex } from "@hawa/contracts";
import { confidenceWord, wardLabel } from "@/lib/format";
import { usePeakHour } from "@/hooks/usePeakHour";
import { dayTime } from "@/lib/time";
import { useConsole } from "@/stores/console";

export default function ForecastPage() {
  const { hour, setHour, thresholdUgm3, ward, selectHotspot, setWard } = useConsole();
  const f = useForecast(ward);
  const stations = useMapStations(hour);
  const peak = usePeakHour();
  const [checklist, setChecklist] = useState(false);

  useEffect(() => {
    if (useConsole.getState().hour <= 0) setHour(peak);
  }, [setHour, peak]);

  const wards = [...(f.data?.wards ?? [])].sort((a, b) => b.peopleHours - a.peopleHours);
  const totalPh = wards.reduce((s, w) => s + w.peopleHours, 0) || 1;
  const topShare = wards[0] ? wards[0].peopleHours / totalPh : 1;

  return (
    <Screen
      headline={wards.length >= 2 ? `${wardLabel(wards[0]!.ward)} and ${wardLabel(wards[1]!.ward)} will carry the most exposure.` : "Loading the forecast…"}
      aside={
        f.error ? <QueryError error={f.error} /> : (
          <>
            <div className="panel-head flex flex-col gap-[3px]">
              <span className="text-base font-semibold">Share of city exposure</span>
              <span title="Exposure = excess PM2.5 × people × vulnerability × time, as each ward's share of the city total" className="cursor-help text-[13.5px] text-muted">Thursday 06:00–10:00, by ward</span>
            </div>
            <div className="grid grid-cols-[84px_minmax(0,1fr)_52px] gap-x-3 border-b border-line px-[18px] py-[9px] text-[13px] font-medium text-muted">
              <span>Ward</span><span>Share of exposure</span><span className="text-right">Peak</span>
            </div>
            {wards.map((w) => {
              const mine = w.ward === ward;
              return (
                <button key={w.ward} onClick={() => setWard(w.ward)} aria-pressed={mine} title={`${confidenceWord(w.confidence)} confidence (${w.confidence.toFixed(2)})`} className={`grid w-full grid-cols-[84px_minmax(0,1fr)_52px] items-center gap-x-3 border-b border-line-soft px-[18px] py-2.5 text-left text-sm hover:bg-hover ${mine ? "row-selected" : ""}`}>
                  <span className={`truncate ${mine ? "font-medium" : ""}`}>{wardLabel(w.ward)}</span>
                  <span className="flex items-center gap-2">
                    <span className="h-2 flex-1 overflow-hidden rounded-sm bg-line-soft"><i className="block h-full origin-left animate-[barIn_.8s_cubic-bezier(.2,.7,.2,1)_both] rounded-sm bg-teal" style={{ width: `${Math.max(4, (w.peopleHours / totalPh / topShare) * 100)}%` }} /></span>
                    <span className="w-10 text-right font-mono text-[12.5px]">{((w.peopleHours / totalPh) * 100).toFixed(1)}%</span>
                  </span>
                  <span className="flex items-center justify-end gap-1.5 text-right font-mono text-[13px]">
                    <i className="size-2 rounded-sm" style={{ background: bandColor(pm25BandIndex(w.peakPm25)) }} />{w.peakPm25}
                  </span>
                </button>
              );
            })}
            <div className="flex flex-col gap-2 px-[18px] py-3.5">
              <span className="text-[13.5px] text-muted">{wardLabel(ward)} PM2.5, likely range</span>
              {f.data && <ForecastChart series={f.data.series} hour={peak} />}
              <Link href="/plans/214" className="btn btn-lg btn-primary mt-1.5"><GitPullRequest size={14} />Review Plan #214</Link>
            </div>
          </>
        )
      }
    >
      <div className="relative min-h-0 flex-1" data-screen-label="Forecast">
        <HawaMap
          layers={["hex", "stations", "causes", "buses", "trucks", "schools"]}
          hour={hour}
          thresholdUgm3={thresholdUgm3}
          maxLabels={3}
          attributionBottom={74}
          assets={["T-12", "ASG-07", "SW-03", "I-3"]}
          labels="full"
          stations={stations}
          onHotspotClick={selectHotspot}
        />
        {f.data && (
          <div
            title={`P50 PM2.5 ${f.data.series.find((p) => p.h === peak)?.p50 ?? "—"} µg/m³ · P90 ${f.data.series.find((p) => p.h === peak)?.p90 ?? "—"} µg/m³ at +${peak} h · probability ${f.data.grap.probability.toFixed(2)} · issued ${dayTime(f.data.issuedAt)}`}
            className="absolute inset-x-3 top-3 flex animate-pin flex-wrap items-center gap-3 rounded-lg border border-line bg-white py-2 pl-3.5 pr-2 shadow-[0_4px_16px_rgba(11,18,21,.06)]"
          >
            <TriangleAlert size={17} className="text-danger" />
            <span className="min-w-[260px] flex-1 text-[14.5px] font-medium">{f.data.grap.headline}</span>
            {f.data.grap.actions.length > 0 && (
              <button onClick={() => setChecklist(!checklist)} aria-expanded={checklist} className="btn btn-quiet h-[30px] px-3 text-[13px]">
                Stage {f.data.grap.stage} checklist
              </button>
            )}
            {checklist && (
              <ul className="m-0 flex w-full list-disc flex-col gap-1 pb-1 pl-8 pr-2 text-[13.5px] text-muted">
                {f.data.grap.actions.map((a) => <li key={a}>{a}</li>)}
              </ul>
            )}
          </div>
        )}
        <Legend thresholdUgm3={thresholdUgm3} />
        <TimeScrubber hour={hour} onChange={setHour} />
      </div>
    </Screen>
  );
}
