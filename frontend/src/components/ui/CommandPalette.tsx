"use client";
// Cmd+K: jump between screens and run common officer commands
import { BadgeCheck, Columns2, GitPullRequest, GitPullRequestCreate, School, Search, TrendingUp, Truck, type LucideIcon } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { useFleet } from "@/hooks/useConsoleData";
import { useWardHotspots } from "@/hooks/useHotspots";
import { usePeakHour } from "@/hooks/usePeakHour";
import { useDraftPlan, usePlans } from "@/hooks/usePlan";
import { addHours, dayTime, now } from "@/lib/time";
import { useConsole } from "@/stores/console";
import { wardLabel } from "@/lib/format";

type Cmd = { icon: LucideIcon; label: string; hint: string; run: () => void };

export function CommandPalette() {
  const router = useRouter();
  const { paletteOpen, setPalette, setLayers, setHour, ward, showToast } = useConsole();
  const peak = usePeakHour();
  const plan = usePlans().data?.items[0];
  const asset = useFleet().data?.items[0];
  const nearSchools = useWardHotspots(0).data?.items.filter((h) => h.schools.length > 0).length;
  const draft = useDraftPlan((p) => {
    setPalette(false);
    showToast({ title: `Draft plan #${p.id} created`, body: "Review it before anything is dispatched." });
    router.push(`/plans/${p.id}`);
  });
  const [query, setQuery] = useState("");
  const [qi, setQi] = useState(0);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setQuery(""); setQi(0);
        setPalette(!useConsole.getState().paletteOpen);
      }
      if (e.key === "Escape") setPalette(false);
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [setPalette]);

  const all: Cmd[] = useMemo(() => {
    const go = (href: string) => () => { setPalette(false); router.push(href); };
    const cmds: (Cmd | false | undefined)[] = [
      { icon: School, label: "Show hotspots near schools", hint: nearSchools === undefined ? "Map" : `${nearSchools} results`, run: () => { setLayers({ heat: true, hotspots: true, trails: false, trucks: false, schools: true }); go("/map")(); } },
      { icon: GitPullRequestCreate, label: `Draft plan for ${ward}`, hint: draft.isPending ? "Drafting…" : "Creates a draft for review", run: () => draft.mutate(ward) },
      plan && { icon: GitPullRequest, label: `Open Plan #${plan.id}`, hint: `${wardLabel(plan.ward)} · ${plan.status.replace("_", " ")}`, run: go(`/plans/${plan.id}`) },
      { icon: TrendingUp, label: `Jump to peak forecast (${dayTime(addHours(now(), peak))})`, hint: "Forecast", run: () => { setHour(peak); go("/forecast")(); } },
      plan && { icon: Columns2, label: `Compare Plan #${plan.id} with usual routes`, hint: "What-If", run: go("/what-if") },
      { icon: BadgeCheck, label: "Which sprinkler runs worked this week?", hint: "Impact", run: go("/impact") },
      asset && { icon: Truck, label: `Where is ${asset.id}?`, hint: "Fleet", run: go(`/fleet?asset=${asset.id}`) },
    ];
    return cmds.filter((c): c is Cmd => Boolean(c));
  }, [router, setPalette, setLayers, setHour, ward, peak, plan, asset, nearSchools, draft]);

  if (!paletteOpen) return null;
  const q = query.trim().toLowerCase();
  const cmds = all.filter((c) => !q || c.label.toLowerCase().includes(q) || c.hint.toLowerCase().includes(q));
  const sel = Math.min(qi, Math.max(0, cmds.length - 1));

  return (
    <div onClick={() => setPalette(false)} className="fixed inset-0 z-50 flex justify-center bg-ink/30 pt-[14vh]">
      <div onClick={(e) => e.stopPropagation()} className="h-fit w-[620px] max-w-[calc(100%-32px)] animate-pin overflow-hidden rounded-xl border border-line bg-white shadow-modal">
        <div className="flex items-center gap-2.5 border-b border-line px-4 py-3.5 text-muted">
          <Search size={16} />
          <input
            autoFocus
            value={query}
            onChange={(e) => { setQuery(e.target.value); setQi(0); }}
            onKeyDown={(e) => {
              if (e.key === "ArrowDown") { e.preventDefault(); setQi(Math.min(cmds.length - 1, sel + 1)); }
              if (e.key === "ArrowUp") { e.preventDefault(); setQi(Math.max(0, sel - 1)); }
              if (e.key === "Enter") cmds[sel]?.run();
            }}
            placeholder="Type a command or search…"
            className="flex-1 bg-transparent text-[15.5px] text-ink outline-none"
          />
          <span className="rounded border border-line px-1.5 py-px text-xs">esc</span>
        </div>
        <div className="max-h-[380px] overflow-auto p-1.5">
          {cmds.map((c, i) => (
            <div key={c.label} onClick={c.run} onMouseEnter={() => setQi(i)} className={`flex cursor-pointer items-center gap-3 rounded-md p-2.5 text-[14.5px] ${i === sel ? "bg-hover" : ""}`}>
              <c.icon size={16} className="text-muted" />
              <span className="flex-1">{c.label}</span>
              <span className="text-[13px] text-muted">{c.hint}</span>
            </div>
          ))}
          {cmds.length === 0 && <div className="px-2.5 py-[18px] text-sm text-muted">No commands match. Try “plan”, “forecast” or a ward name.</div>}
        </div>
      </div>
    </div>
  );
}
