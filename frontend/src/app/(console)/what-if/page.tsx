"use client";
// SCREEN D What-If: usual vs plan maps + per-asset route comparison
import Link from "next/link";
import { useMemo } from "react";
import { HawaMap, MapBadge } from "@/components/map/HawaMap";
import { Fact, Screen } from "@/components/shell/Screen";
import { applyPlan, centroid, planReduction } from "@/components/map/layers";
import { useMapStations } from "@/components/map/useMapStations";
import { usePeakHour } from "@/hooks/usePeakHour";
import { usePlan, usePlanComparison, usePlans } from "@/hooks/usePlan";
import { fmtInt, fmtPct, fmtRange } from "@/lib/format";
import { clock, windowLabel } from "@/lib/time";
import { useConsole } from "@/stores/console";

const COLS = "grid min-w-[720px] grid-cols-[64px_minmax(0,1fr)_minmax(0,1fr)_84px_124px_88px] gap-x-3 px-4 py-2.5";
const EXTRUDE = { pitch: 50, bearing: -20, hscale: 6 };
const km = (a: number | null, b: number | null) => (a === null || b === null ? "—" : `${a.toFixed(1)} → ${b.toFixed(1)}`);

export default function WhatIfPage() {
  const threshold = useConsole((s) => s.thresholdUgm3);
  const PLAN_ID = usePlans().data?.items[0]?.id ?? "";
  const plan = usePlan(PLAN_ID).data;
  const cmp = usePlanComparison(PLAN_ID).data;
  const peak = usePeakHour();
  const usual = useMapStations(peak);
  const planned = useMemo(() => applyPlan(usual, planReduction(plan?.headline), threshold), [usual, plan, threshold]);
  const h = plan?.headline;
  const shared = { layers: ["hex", "stations", "trucks", "schools", "buildings"] as const, hour: peak, thresholdUgm3: threshold, maxLabels: 3, extrude: EXTRUDE, assets: ["T-12", "ASG-07", "SW-03", "I-3"], labels: "major" as const, center: (centroid(usual) ?? [77.305, 28.635]) as [number, number], zoom: 11.2 };

  return (
    <Screen
      headline={`Same fleet, different targets: usual routes against Plan #${PLAN_ID}.`}
      aside={h && (
        <div className="flex flex-col gap-3 px-[18px] py-4 text-sm">
          <span className="text-base font-semibold">Assumptions</span>
          <div className="[&_.fact-row]:!border-0 [&_.fact-row]:!py-0 [&_.fact-row_span:last-child]:font-normal flex flex-col gap-3">
            <Fact k="People-hours">{fmtInt(h.peopleHoursUsual)} → {fmtInt(h.peopleHoursPlan)}</Fact>
            <Fact k="Likely saving">{fmtRange(h.likelyRange)}</Fact>
            <Fact k="Fleet">{h.assetsUsed} of {h.assetsTotal} assets, unchanged</Fact>
            <Fact k="Window">{windowLabel(plan.window)}</Fact>
            <Fact k="Forecast">Median, issued {clock(plan.draftedAt)}</Fact>
            <Fact k="Effects from">Library, weather-matched</Fact>
            <Fact k="Extra distance">+{h.extraKm} km</Fact>
          </div>
          <p className="m-0 mt-1 text-pretty rounded-md border border-line bg-paper px-3 py-2.5 text-[13.5px] leading-normal text-muted">Simulated. After dispatch, measured effects replace this estimate.</p>
          <Link href={`/plans/${PLAN_ID}`} className="btn btn-lg btn-primary">Back to review</Link>
        </div>
      )}
    >
      <div className="flex min-h-0 flex-1 flex-col" data-screen-label="What-If">
        <div className="grid min-h-0 flex-1 grid-cols-[minmax(0,1fr)_168px_minmax(0,1fr)]">
          <div className="relative border-r border-line">
            <HawaMap {...shared} layers={[...shared.layers]} mode="usual" attribution={false} stations={usual} />
            <MapBadge>Usual routes</MapBadge>
          </div>
          <div className="flex flex-col items-center justify-center gap-1.5 bg-white p-4 text-center">
            <span className="text-[44px] font-semibold leading-none tracking-[-.035em]">{cmp ? fmtPct(cmp.deltaPct) : "—"}</span>
            <span className="text-balance text-sm leading-[1.4] text-muted">less exposure, same fleet</span>
          </div>
          <div className="relative border-l border-line">
            <HawaMap {...shared} layers={[...shared.layers]} mode="plan" stations={planned} />
            <MapBadge accent>Plan #{PLAN_ID}</MapBadge>
          </div>
        </div>
        <div className="h-60 overflow-auto border-t border-line bg-white">
          <div className={`${COLS} sticky top-0 border-b border-line bg-white text-[13px] font-medium text-muted`}>
            <span>Asset</span><span>Usual route</span><span>Plan route</span><span className="text-right">km</span><span className="text-right">People-hours reached</span><span className="text-right">Exposure change</span>
          </div>
          {cmp?.rows.map((r) => (
            <div key={r.asset} className={`${COLS} items-center border-b border-line-soft text-sm`}>
              <span className="font-mono text-[13px] font-medium">{r.asset}</span>
              <span className="text-muted">{r.usual}</span>
              <span>{r.plan}</span>
              <span className="text-right font-mono text-[13px] text-muted">{km(r.kmUsual, r.kmPlan)}</span>
              <span className="text-right font-mono text-[13px] text-muted">{r.reachUsual} → {r.reachPlan}</span>
              <span className="text-right font-mono text-[13px] font-medium">−{fmtInt(Math.abs(r.exposureDelta))}</span>
            </div>
          ))}
        </div>
      </div>
    </Screen>
  );
}
