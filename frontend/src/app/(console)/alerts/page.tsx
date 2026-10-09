"use client";
// SCREEN G Alerts log + WhatsApp preview
import { useState } from "react";
import { AlertStats } from "@/components/alerts/AlertStats";
import { AlertsTable } from "@/components/alerts/AlertsTable";
import { WhatsAppPreview } from "@/components/alerts/WhatsAppPreview";
import { Screen } from "@/components/shell/Screen";
import { QueryError } from "@/components/ui/Skeleton";
import { useAlerts } from "@/hooks/useConsoleData";

const FILTERS = ["All", "School", "Citizens", "Citizen Eyes"] as const;
const LABEL: Record<(typeof FILTERS)[number], string> = { All: "All", School: "Schools", Citizens: "Citizens", "Citizen Eyes": "Citizen Eyes" };

export default function AlertsPage() {
  const q = useAlerts();
  const [filter, setFilter] = useState<(typeof FILTERS)[number]>("All");
  const [sel, setSel] = useState("");
  const items = (q.data?.items ?? []).filter((a) => filter === "All" || a.audience === filter);
  const a = q.data?.items.find((x) => x.id === sel) ?? items[0];
  const lead = (q.data?.items ?? []).find((x) => x.audience === "School" && x.leadTimeH !== null);
  const headline = lead ? `${lead.target} were warned ${lead.leadTimeH} hours before the spike.` : q.data ? `${q.data.items.length} alerts sent.` : "Alerts";

  return (
    <Screen headline={headline} aside={a && <WhatsAppPreview a={a} />}>
      <div className="flex min-h-0 flex-1 flex-col gap-3.5 overflow-auto px-[clamp(20px,2.4vw,40px)] pb-10 pt-5" data-screen-label="Alerts">
        <AlertStats items={q.data?.items ?? []} />
        <div className="flex flex-wrap gap-0.5 self-start rounded-lg border border-line bg-white p-[3px]">
          {FILTERS.map((f) => (
            <button key={f} onClick={() => setFilter(f)} className={`rounded-md px-[11px] py-[5px] text-[13.5px] ${filter === f ? "bg-hover font-medium" : "text-muted"}`}>
              {LABEL[f]} {q.data?.counts[f] ?? ""}
            </button>
          ))}
        </div>
        {q.error ? <QueryError error={q.error} /> : <AlertsTable items={items} selected={a?.id ?? ""} onPick={setSel} />}
      </div>
    </Screen>
  );
}
