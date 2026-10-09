"use client";
// what runs where on AWS + district pilot cost
import { useInView } from "../useInView";
import { Section } from "./ui";

// status is what is true in this repo today: built | wired (code + tests, behind HAWA_AWS_ENABLED, not deployed) | planned | simulated
const TOWER = [
  ["Act", "Officer console · Driver PWA · SNS alerts", "wired", "62%", "#0F766E", "#FFFFFF"],
  ["Agents", "Planner + Auditor agents · Bedrock next", "built", "70%", "#2E4750", "#FFFFFF"],
  ["Think", "OR-Tools routing · SageMaker + Step Functions hooks", "wired", "78%", "#5F7F8A", "#FFFFFF"],
  ["Store", "Postgres + PostGIS models · DynamoDB cache", "wired", "86%", "#C9B28A", "#0B1215"],
  ["Ingest", "Kinesis publisher · IoT Core and Lambda next", "planned", "94%", "#D9C7A4", "#0B1215"],
  ["Edge", "HawaPod-M · HawaPod-S · HawaTag", "simulated", "100%", "#E8DCC2", "#0B1215"],
] as const;

const STATUS: Record<(typeof TOWER)[number][2], string> = {
  built: "Built",
  wired: "Wired, not deployed",
  planned: "Planned",
  simulated: "Simulated",
};

export function Aws() {
  return (
    <Section id="aws" label="AWS">
      <div className="grid items-stretch gap-3 [grid-template-columns:repeat(auto-fit,minmax(min(100%,420px),1fr))]">
        <div className="flex flex-col gap-4 rounded-lg border border-ink/[.08] bg-paper/90 p-8 lg:p-12">
          <div className="flex items-center gap-2.5 text-[12.5px] font-semibold uppercase tracking-[.09em] text-teal"><span className="font-mono tracking-normal">08</span><i className="h-px w-8 bg-teal" />Built for AWS</div>
          <h2 className="m-0 text-balance text-[clamp(34px,3.8vw,58px)] font-semibold leading-[1.03] tracking-[-.035em]">What runs where, and how far along it is</h2>
          <p className="m-0 text-base leading-[1.6] text-muted-3">The app, the models and the optimiser run today. The AWS layer (DynamoDB cache, SageMaker and Step Functions calls, SNS alerts, Kinesis publishing) is implemented behind one feature flag and tested against mocks. It is not deployed yet. A deterministic optimiser proposes, agents explain and critique, and nothing dispatches without an officer.</p>
          <div className="mt-auto flex flex-col gap-1.5 border-t border-line pt-4 text-[13px] text-muted-2">
            <span>Console sign-in · Cognito supported, off in the demo</span><span>Planned · EventBridge, CloudWatch, Timestream, S3</span>
          </div>
        </div>
        <div className="flex flex-col items-center justify-end gap-1 rounded-lg border border-ink/[.08] bg-paper/70 p-7">
          {TOWER.map(([layer, items, status, w, c, fg]) => (
            <div key={layer} className="flex flex-col gap-1 px-4 py-3 shadow-[inset_-4px_-4px_0_rgba(0,0,0,.16),inset_4px_4px_0_rgba(255,255,255,.3)]" style={{ width: w, background: c, color: fg }}>
              <div className="flex items-center gap-3.5">
                <span className="w-16 flex-none text-[13px] font-semibold">{layer}</span>
                <span className="text-sm font-medium leading-[1.4]">{items}</span>
              </div>
              <span className="pl-[78px] text-[11.5px] font-medium uppercase tracking-[.08em] opacity-80">{STATUS[status]}</span>
            </div>
          ))}
          <div className="mt-0.5 h-2 w-full bg-[#8E8A80]" />
        </div>
      </div>
    </Section>
  );
}

export function Cost() {
  const [ref, on] = useInView<HTMLDivElement>(0.3);
  return (
    <Section id="cost" label="Cost">
      <div ref={ref} className="relative overflow-hidden rounded-lg border border-line bg-white p-8 lg:p-10">
        <div className="pointer-events-none absolute -right-6 bottom-0 top-0 w-[34%] opacity-95 max-lg:hidden">
          <px-scene kind="podtower" stage="0.85" style={{ display: "block", width: "100%", height: "100%" }} />
          <div className="absolute inset-0 bg-gradient-to-r from-white via-white/70 to-transparent" />
        </div>
        <div className="relative max-w-[760px]">
          <div className="mb-3 flex items-center gap-2 text-[12.5px] font-semibold uppercase tracking-[.09em] text-teal"><i className="size-1.5 bg-teal" />Cost, estimated</div>
          <h2 className="m-0 text-balance text-[clamp(32px,3.6vw,48px)] font-semibold leading-[1.05] tracking-[-.03em]">A district pilot costs about a hundredth of one smog tower</h2>
          <div className="mt-9 flex flex-col gap-7">
            <div>
              <div className="mb-2 flex flex-wrap items-baseline gap-x-4 gap-y-1"><span className="text-[clamp(30px,3.6vw,52px)] font-semibold leading-none tracking-[-.035em] text-teal">≈ ₹22–24 lakh</span><span className="text-sm text-muted-3">District pilot, year one: 100 HawaPod-M, 20 school pairs, 50 HawaTags, 4G data and AWS.</span></div>
              <i className="block h-3 origin-left rounded-sm bg-teal transition-transform duration-[1600ms] ease-[cubic-bezier(.2,.7,.2,1)]" style={{ width: "1.1%", minWidth: 6, transform: on ? "scaleX(1)" : "scaleX(0)" }} />
            </div>
            <div>
              <div className="mb-2 flex flex-wrap items-baseline gap-x-4 gap-y-1"><span className="text-[clamp(30px,3.6vw,52px)] font-semibold leading-none tracking-[-.035em]">≈ ₹20–22 crore</span><span className="text-sm text-muted-3">One smog tower. Build only, plus about ₹15 lakh a month to run.</span></div>
              <i className="block h-3 w-full origin-left rounded-sm bg-ink/80 transition-transform duration-[2200ms] ease-[cubic-bezier(.2,.7,.2,1)]" style={{ transform: on ? "scaleX(1)" : "scaleX(0)" }} />
            </div>
          </div>
        </div>
      </div>
    </Section>
  );
}
