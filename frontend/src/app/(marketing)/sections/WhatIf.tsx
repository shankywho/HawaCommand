"use client";
// usual routes -> plan slider; numbers and map come from the same plan and hotspots the console shows
import { useMemo, useState } from "react";
import { BAND_COLORS } from "@hawa/contracts";
import { HawaMap } from "@/components/map/HawaMap";
import { applyPlan, centroid, planReduction } from "@/components/map/layers";
import { useMapStations } from "@/components/map/useMapStations";
import { CountUp } from "@/components/ui/CountUp";
import { usePeakHour } from "@/hooks/usePeakHour";
import { usePlan, usePlans } from "@/hooks/usePlan";
import { windowLabel } from "@/lib/time";
import { Section } from "./ui";
import { wardLabel } from "@/lib/format";

export function WhatIf() {
  const [mix, setMix] = useState(0.5);
  const planId = usePlans().data?.items[0]?.id ?? "";
  const plan = usePlan(planId).data;
  const h = plan?.headline;
  const peak = usePeakHour();
  const usual = useMapStations(peak);
  const stations = useMemo(() => applyPlan(usual, planReduction(h) * mix, 250), [usual, h, mix]);

  return (
    <Section id="whatif" label="What-If">
      <div className="grid gap-3 lg:[grid-template-columns:minmax(0,.8fr)_minmax(0,1.3fr)]">
        <div className="flex flex-col gap-6 rounded-lg border border-ink/[.08] bg-paper/95 p-8 lg:p-12">
          <div>
            <div className="mb-4 flex items-center gap-2.5 text-[12.5px] font-semibold uppercase tracking-[.09em] text-teal"><span className="font-mono tracking-normal">04</span><i className="h-px w-8 bg-teal" />What-if</div>
            <h2 className="mb-3 mt-0 text-balance text-[clamp(34px,3.8vw,58px)] font-semibold leading-[1.05] tracking-[-.03em]">Same trucks, same shift: usual routes vs. the plan</h2>
            <p className="m-0 text-base leading-[1.6] text-muted-3">Move the slider from the usual routes to the plan. Colour is forecast PM2.5 at the morning peak. The fleet doesn&apos;t change, only the streets it goes to.</p>
          </div>
          <div className="flex flex-col gap-2">
            <input type="range" min={0} max={100} value={Math.round(mix * 100)} onChange={(e) => setMix(Number(e.target.value) / 100)} aria-label="Usual routes to HawaCommand plan" className="h-6 w-full cursor-pointer accent-teal" />
            <div className="flex justify-between text-sm text-muted-3"><span>Usual routes</span><span className="text-teal">HawaCommand plan</span></div>
          </div>
          <div className="border-t border-line pt-5">
            <div className="mb-1.5 text-sm text-muted-2">Person-hours of exposure avoided</div>
            <div className="text-[clamp(56px,6vw,80px)] font-semibold leading-none tracking-[-.04em]"><CountUp to={h ? Math.round(h.peopleHoursSaved * mix) : 0} dur={400} /></div>
            <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-sm">
              <span className="text-teal">+{h ? Math.round(h.protectedPct * mix) : 0}% more people protected</span>
              <span className="text-muted-2">{plan ? `Plan #${plan.id} · ${wardLabel(plan.ward)} · ${windowLabel(plan.window)} · simulated` : "Loading plan…"}</span>
            </div>
          </div>
        </div>
        <div className="relative min-h-[560px] overflow-hidden rounded-lg border border-ink/[.12] bg-[#F2F0EB]">
          <HawaMap layers={["hex", "trucks"]} mix={mix} hour={peak} stations={stations} extrude={{ pitch: 50, bearing: -20, hscale: 6 }} center={centroid(usual) ?? [77.3, 28.635]} zoom={11.2} assets={["T-12", "ASG-07", "SW-03", "I-3"]} interactive={false} />
          <div className="absolute left-4 top-4 flex flex-wrap gap-1.5">
            <span className="inline-flex h-[26px] items-center gap-1.5 whitespace-nowrap rounded-md border border-line bg-white px-[9px] text-[13px]"><i className="w-3 border-t-2 border-dashed border-muted-2" />Usual route</span>
            <span className="inline-flex h-[26px] items-center gap-1.5 whitespace-nowrap rounded-md border border-line bg-white px-[9px] text-[13px]"><i className="w-3 border-t-2 border-dashed border-teal" />AI plan</span>
          </div>
          <div className="absolute inset-x-4 bottom-[22px] grid grid-cols-6 gap-0.5">
            {BAND_COLORS.map((c) => <i key={c} className="h-1.5" style={{ background: c }} />)}
          </div>
        </div>
      </div>
    </Section>
  );
}
