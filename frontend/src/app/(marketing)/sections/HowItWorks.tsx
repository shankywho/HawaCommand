"use client";
// scroll-linked 7 steps over light map
import { useEffect, useRef, useState } from "react";
import { HawaMap } from "@/components/map/HawaMap";
import type { MapLayer } from "@/components/map/layers";

const STEPS = [
  ["Sense", "Sensors on buses and bikes, school sentinels, trackers on cleaning trucks, official stations, weather and satellite fire data all feed one pipeline. In this demo the sensor fleet is simulated."],
  ["Map", "The city is cut into 500 m cells. A digital twin fills the gaps between sensors and gives every cell a value and a confidence."],
  ["Attribute", "Each hotspot gets a likely cause (road dust, traffic, burning, regional smoke) and an upwind suspect location."],
  ["Forecast", "A 72-hour forecast per 1 km cell, and the GRAP stage it will trigger, 24–48 hours before it is invoked."],
  ["Decide", "Planner agents rank cells by people exposed and assign machines to causes they can fix. An Auditor agent challenges the plan. An officer approves."],
  ["Act", "Drivers receive routes, inspectors receive targets, and schools in the path receive a warning with a safe window."],
  ["Verify", "HawaTag logs exactly when the truck sprayed. The cell is compared with similar untreated cells to record the true effect."],
] as const;

const VIEWS: [MapLayer[], number, "live" | "plan" | "donor", "none" | "major", string][] = [
  [["stations", "buses", "trucks"], 0, "live", "none", "CAAQMS stations + bus sensor trails"],
  [["hex", "stations", "buses"], 0, "live", "none", "500 m twin · now"],
  [["hex", "stations", "causes", "suspect"], 0, "live", "major", "Cause + upwind suspect"],
  [["hex", "stations"], 42, "live", "major", "Forecast · morning peak"],
  [["hex", "trucks", "stations"], 42, "plan", "none", "Draft plan routes"],
  [["hex", "trucks", "schools", "stations"], 42, "plan", "none", "After approval · schools warned"],
  [["hex"], 42, "donor", "none", "Treated cell vs 5 donor cells"],
];

export function HowItWorks() {
  const ref = useRef<HTMLElement>(null);
  const [step, setStep] = useState(0);

  useEffect(() => {
    const on = () => {
      const el = ref.current;
      if (!el) return;
      const r = el.getBoundingClientRect();
      const p = Math.min(0.999, Math.max(0, -r.top / Math.max(1, r.height - innerHeight)));
      setStep(Math.floor(p * 7));
    };
    on();
    addEventListener("scroll", on, { passive: true });
    return () => removeEventListener("scroll", on);
  }, []);

  const [layers, hour, mode, labels, caption] = VIEWS[step]!;
  const center: [number, number] = step === 6 ? [77.316, 28.647] : step >= 4 ? [77.3, 28.635] : [77.19, 28.64];
  const zoom = step === 6 ? 13.2 : step >= 4 ? 12.2 : 10.2;

  return (
    <section id="how" ref={ref} data-screen-label="How it works" className="relative h-[520vh] bg-[#EFE6D8]">
      <div className="sticky top-0 mx-auto grid h-screen max-w-[1280px] auto-rows-[minmax(0,1fr)] gap-8 px-8 pb-8 pt-[88px] [grid-template-columns:repeat(auto-fit,minmax(min(100%,360px),1fr))] ">
        <div className="flex min-h-0 flex-col">
          <div className="mb-2.5 text-[15px] text-muted">How it works</div>
          <h2 className="mb-7 mt-0 text-[clamp(30px,3vw,42px)] font-semibold leading-[1.04] tracking-[-.03em]">Every three hours, the same seven steps.</h2>
          <ol className="m-0 flex list-none flex-col p-0">
            {STEPS.map(([name, desc], i) => (
              <li key={name} className="grid grid-cols-[36px_minmax(0,1fr)] gap-2 border-t border-ink/15 py-3 transition-opacity" style={{ opacity: i === step ? 1 : i < step ? 0.55 : 0.4 }}>
                <span className="pt-[3px] text-sm font-medium" style={{ color: i === step ? "#0F766E" : "#6B5A45" }}>{String(i + 1).padStart(2, "0")}</span>
                <div>
                  <div className="text-[19px] tracking-[-.015em]" style={{ fontWeight: i === step ? 600 : 500 }}>{name}</div>
                  {i === step && <p className="mb-0 mt-1.5 text-pretty text-[15px] leading-[1.55] text-muted-3">{desc}</p>}
                </div>
              </li>
            ))}
          </ol>
        </div>
        <div className="relative min-h-0 overflow-hidden rounded-[10px] border border-ink/[.12] bg-[#F2F0EB]">
          <HawaMap layers={layers} hour={hour} mode={mode} labels={labels} thresholdUgm3={step === 4 || step === 5 ? 250 : undefined} center={center} zoom={zoom} interactive={false} />
          <span className="absolute left-3.5 top-3.5 flex h-7 items-center whitespace-nowrap rounded-md border border-line bg-white px-2.5 text-[13px]">{caption}</span>
        </div>
      </div>
    </section>
  );
}
