"use client";
// SCREEN E Impact: verified interventions table + observed vs synthetic control chart
import { FileText } from "lucide-react";
import { useState } from "react";
import { EffectLibrary } from "@/components/impact/EffectLibrary";
import { ImpactTable } from "@/components/impact/ImpactTable";
import { InterventionDetail } from "@/components/impact/InterventionDetail";
import { downloadText, evidenceReport } from "@/components/impact/report";
import { Fact, Screen } from "@/components/shell/Screen";
import { QueryError, Skeleton } from "@/components/ui/Skeleton";
import { useEffectLibrary, useInterventions } from "@/hooks/useConsoleData";

export default function ImpactPage() {
  const q = useInterventions();
  const lib = useEffectLibrary();
  const [sel, setSel] = useState("");
  const items = q.data?.items ?? [];
  const iv = items.find((v) => v.id === sel) ?? items[0];
  const verified = items.filter((v) => v.impact?.verdict === "Verified").length;
  const s = q.data?.summary;

  return (
    <Screen
      headline={s ? `${s.verifiedPct}% of this week's actions had a verified effect (target ${s.targetPct}%).` : "Impact"}
      aside={
        <>
          <div className="panel-head"><span className="text-base font-semibold">What the fleet did this week</span></div>
          {s && (
            <div className="border-b border-line px-[18px] py-1.5">
              <Fact k="Verified actions">{s.verifiedPct}% <span className="font-normal text-muted">of {s.targetPct}% target</span></Fact>
              <Fact k="No measurable effect">{s.noEffect} <span className="font-normal text-muted">· {s.wrongTool} wrong tool for cause</span></Fact>
            </div>
          )}
          <div className="flex flex-col gap-2.5 px-[18px] py-3.5">
            <span className="text-[13.5px] text-muted">What the data suggests</span>
            {[
              s && s.wrongTool > 0 && ["Match tools to causes", `${s.wrongTool} action${s.wrongTool === 1 ? "" : "s"} used the wrong tool for the cause. Check the effect library before assigning assets.`],
              s && s.noEffect > 0 && ["Review actions with no effect", `${s.noEffect} action${s.noEffect === 1 ? "" : "s"} showed no measurable effect. Compare them with the verified ones below.`],
            ].filter((c): c is string[] => Array.isArray(c)).map(([t, b]) => (
              <div key={t} className="flex flex-col gap-1.5 rounded-lg border border-line p-3">
                <span className="text-[14.5px] font-medium">{t}</span>
                <span className="text-pretty text-sm leading-normal text-muted">{b}</span>
              </div>
            ))}
            <button onClick={() => downloadText(`hawa-evidence-report-${new Date().toISOString().slice(0, 10)}.md`, evidenceReport(items, s, lib.data?.items ?? []))} disabled={!items.length} className="btn btn-lg btn-primary mt-1 disabled:opacity-60"><FileText size={14} />Weekly evidence report</button>
          </div>
        </>
      }
    >
      <div className="flex min-h-0 flex-1 flex-col gap-4 overflow-auto px-6 pb-10 pt-5" data-screen-label="Impact" data-verified={verified}>
        {q.error ? <QueryError error={q.error} /> : q.isLoading ? <Skeleton className="h-64 w-full rounded-[10px]" /> : (
          <div className="grid items-start gap-4 [grid-template-columns:repeat(auto-fit,minmax(min(100%,700px),1fr))]">
            <ImpactTable items={items} selected={iv?.id ?? ""} onPick={setSel} />
            {iv?.impact && <InterventionDetail iv={iv} />}
          </div>
        )}
        {lib.data && <EffectLibrary rows={lib.data.items} />}
      </div>
    </Screen>
  );
}
