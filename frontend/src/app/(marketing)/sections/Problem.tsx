"use client";
// the problem as one dark number plus two bars: 376 machines, no impact check, 15% of PM2.5 vs 64% of funds
import { CountUp } from "@/components/ui/CountUp";
import { useInView } from "../useInView";
import { SectionIntro } from "./ui";

const Bar = ({ label, pct, on, tone }: { label: string; pct: number; on: boolean; tone: string }) => (
  <div>
    <div className="mb-2 flex items-baseline justify-between gap-4 text-[15px] text-muted-3"><span>{label}</span><span className="text-[28px] font-semibold tracking-[-.03em] text-ink">{pct}%</span></div>
    <div className="h-3.5 overflow-hidden rounded-sm bg-line-soft">
      <i className={`block h-full origin-left rounded-sm transition-transform duration-[1400ms] ease-[cubic-bezier(.2,.7,.2,1)] ${tone}`} style={{ width: `${pct}%`, transform: on ? "scaleX(1)" : "scaleX(0)" }} />
    </div>
  </div>
);

export function Problem() {
  const [ref, on] = useInView<HTMLDivElement>(0.3);
  return (
    <section id="problem" data-screen-label="Problem" className="mx-auto max-w-[1200px] px-6 pb-12 pt-24">
      <SectionIntro
        index={1}
        eyebrow="The problem"
        title="Delhi has the machines. It has no way to tell if they work."
        body="GPS proves where a machine went. It does not prove the air got cleaner. Routes are largely fixed while hotspots move with wind, traffic and construction."
      />
      <div ref={ref} className="grid gap-3 lg:grid-cols-[minmax(0,1.15fr)_minmax(0,1fr)]">
        <div className="relative flex min-h-[400px] flex-col justify-between gap-8 overflow-hidden rounded-lg border border-line bg-white p-8 lg:p-10">
          <px-scene kind="smoggun" stage="0.05" style={{ position: "absolute", right: 24, top: 24, display: "block", width: 120, aspectRatio: "96/56", borderRadius: 6, overflow: "hidden", opacity: 0.9 }} />
          <div className="text-[13px] font-semibold uppercase tracking-[.09em] text-teal">Deployed across Delhi</div>
          <div>
            <div className="text-[clamp(96px,12vw,180px)] font-semibold leading-[.85] tracking-[-.06em]"><CountUp to={376} dur={1800} /></div>
            <p className="mb-0 mt-6 max-w-[460px] text-pretty text-[17px] leading-normal text-muted-3">anti-smog guns, plus 266 sprinklers and 91 mechanised sweepers. Nobody measures whether a spray run cleaned the air.</p>
          </div>
        </div>
        <div className="flex flex-col gap-3">
          <div className="flex flex-1 flex-col justify-center gap-7 rounded-lg border border-line bg-white p-8 lg:p-10">
            <Bar label="Road dust, share of winter PM2.5" pct={15} on={on} tone="bg-ink" />
            <Bar label="Road dust, share of available NCAP funds" pct={64} on={on} tone="bg-teal" />
            <p className="m-0 text-[13px] leading-normal text-muted-2">Spend follows the visible cause, not the measured one.</p>
          </div>
          <div className="relative overflow-hidden rounded-lg border border-dashed border-ink bg-hover p-8">
            <div className="text-[clamp(30px,3vw,44px)] font-semibold leading-[1.05] tracking-[-.03em]">No routine <span className="underline decoration-teal decoration-[3px] underline-offset-[6px]">impact check</span>.</div>
            <p className="mb-0 mt-3 max-w-[420px] text-[15px] leading-normal text-muted-3">Trucks are scheduled, driven and logged. The result is never compared with similar streets that were left alone.</p>
          </div>
        </div>
      </div>
      <div className="mt-3 inline-block rounded bg-paper/85 px-2 py-1 text-[13px] text-muted-3">Sources: The Tribune (fleet) · CEEW, Feb 2026 (dust vs funds)</div>
    </section>
  );
}
