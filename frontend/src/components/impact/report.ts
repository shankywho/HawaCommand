import type { EffectLibraryRow, Intervention, InterventionList } from "@hawa/contracts";
import { dayTime } from "@/lib/time";
import { pollutantLabel } from "@/lib/format";

const pct = (n: number) => `${n > 0 ? "+" : ""}${n}%`;

/** Plain-markdown weekly evidence report built from the interventions and effect library on screen. */
export function evidenceReport(items: Intervention[], summary: InterventionList["summary"] | undefined, library: EffectLibraryRow[]): string {
  const lines = ["# HawaCommand weekly evidence report", "", `Generated ${dayTime(new Date())}`, ""];
  if (summary) {
    lines.push("## Summary", "", `- Verified actions: ${summary.verifiedPct}% (target ${summary.targetPct}%)`, `- No measurable effect: ${summary.noEffect}`, `- Wrong tool for cause: ${summary.wrongTool}`, "");
  }
  lines.push("## Interventions", "", "| ID | Asset | Place | Action | Effect | 95% CI | Duration | Verdict |", "|---|---|---|---|---|---|---|---|");
  for (const v of items) {
    const im = v.impact;
    lines.push(`| ${v.id} | ${v.asset} | ${v.place} | ${v.action} | ${im ? `${pct(im.effectPct)} ${pollutantLabel(im.pollutant)}` : "n/a"} | ${im ? `${im.ciLow}% to ${im.ciHigh}%` : "n/a"} | ${im ? `${im.durationMin} min` : "n/a"} | ${im?.verdict ?? "pending"} |`);
  }
  if (items.some((v) => v.simulated)) lines.push("", "_Includes simulated interventions with injected effects._");
  if (library.length) {
    lines.push("", "## Effectiveness library", "", "| Action | Cause | Weather | Typical effect | n |", "|---|---|---|---|---|");
    for (const r of library) lines.push(`| ${r.action} | ${r.cause} | ${r.weather} | ${pct(r.effectPct)} [${r.ci[0]}%, ${r.ci[1]}%] | ${r.n} |`);
  }
  return lines.join("\n") + "\n";
}

export function downloadText(filename: string, text: string) {
  const url = URL.createObjectURL(new Blob([text], { type: "text/markdown;charset=utf-8" }));
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
