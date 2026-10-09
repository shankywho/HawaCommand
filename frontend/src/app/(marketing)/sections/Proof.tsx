"use client";
// before/after chart with synthetic control band, from the first intervention in the same API as the console
import { SyntheticControlChart, ChartKey } from "@/components/impact/SyntheticControlChart";
import { Skeleton } from "@/components/ui/Skeleton";
import { useInterventions } from "@/hooks/useConsoleData";
import { dayTime } from "@/lib/time";
import { Section, SectionIntro } from "./ui";
import { pollutantLabel } from "@/lib/format";

export function Proof() {
  const q = useInterventions();
  const iv = q.data?.items.find((v) => v.impact);
  const im = iv?.impact;
  const sign = (n: number) => `${n > 0 ? "+" : ""}${n}%`;
  const rows = iv && im ? [
    ["Effect", `${pollutantLabel(im.pollutant)} ${sign(im.effectPct)}  (CI ${sign(im.ciLow)} to ${sign(im.ciHigh)})`],
    ["Duration", `${im.durationMin} min`],
    ["Action", iv.action],
    ["Method", `Synthetic control · ${im.donorCells.length} donor cells`],
    ["Cell", iv.cellId],
  ] : [];
  const verified = im?.verdict === "Verified";

  return (
    <Section id="proof" label="Proof">
      <SectionIntro
        index={5}
        eyebrow="Proof"
        title="How we check whether a spray run worked"
        body="HawaTag logs exactly when the pump ran. A synthetic control built from similar untreated cells predicts what the air would have done anyway. The difference is the effect."
      />
      <div className="mb-2 ml-0.5 mr-2 mt-5 bg-white shadow-[0_0_0_2px_#0B1215,6px_6px_0_2px_#0B1215]">
        {!iv || !im ? (
          <div className="p-6">
            {q.isError ? <p className="m-0 text-sm text-muted-2">Couldn&apos;t load the intervention. Open the console to see verified runs.</p> : <Skeleton className="h-[330px] w-full" />}
          </div>
        ) : (
          <>
            <div className="flex flex-wrap items-center justify-between gap-3 border-b border-line bg-hover px-5 py-3 text-ink">
              <span className="text-sm font-medium">Progress report · intervention {iv.id}</span>
              <span className="text-[13px] text-muted-2">{iv.place} · {dayTime(iv.startedAt)}</span>
            </div>
            <div className="grid [grid-template-columns:repeat(auto-fit,minmax(min(100%,420px),1fr))]">
              <div className="border-r border-line p-6">
                <div className="mb-1 text-xl font-medium tracking-[-.01em]">{iv.asset} · {iv.action} · {pollutantLabel(im.pollutant)} {sign(im.effectPct)} for {im.durationMin} min · {im.verdict.toLowerCase()}</div>
                <ChartKey />
                <SyntheticControlChart impact={im} asset={iv.asset} height={240} />
              </div>
              <div className="flex flex-col">
                {rows.map(([k, v]) => (
                  <div key={k} className="grid grid-cols-[120px_minmax(0,1fr)] items-baseline gap-3 border-b border-line px-6 py-3.5">
                    <span className="text-[13px] text-muted-2">{k}</span><span className="text-[15px] font-medium">{v}</span>
                  </div>
                ))}
                <div className="mt-auto flex items-center gap-4 px-6 py-5">
                  <span className={`inline-block -rotate-[4deg] rounded-md border-2 px-3.5 py-[7px] text-base font-semibold ${verified ? "border-teal text-teal" : "border-muted-2 text-muted-2"}`}>{im.verdict}</span>
                  <span className="text-[13px] leading-normal text-muted-2">{iv.simulated ? "This intervention is simulated with an injected, known effect, so you can see the verifier recover it." : "Measured from HawaTag spray logs and sensor readings."}</span>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </Section>
  );
}
