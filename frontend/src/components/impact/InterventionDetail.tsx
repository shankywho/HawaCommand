import type { Intervention } from "@hawa/contracts";
import { useMemo } from "react";
import { BadgeCheck, CircleDashed } from "lucide-react";
import { HawaMap, MapBadge } from "@/components/map/HawaMap";
import { useFleet } from "@/hooks/useConsoleData";
import { useHotspots } from "@/hooks/useHotspots";
import { fmtPct, pollutantLabel } from "@/lib/format";
import { ChartKey, SyntheticControlChart } from "./SyntheticControlChart";

export function InterventionDetail({ iv }: { iv: Intervention }) {
  const im = iv.impact!;
  const hotspots = useHotspots(0).data?.items;
  const fleet = useFleet().data?.items;
  const at = hotspots?.find((h) => h.cellId === iv.cellId)?.at ?? fleet?.find((a) => a.id === iv.asset)?.at;
  const weights = useMemo(() => im.donorCells.map((d) => d.weight), [im.donorCells]);
  const facts = [
    ["Effect", `${fmtPct(im.effectPct)} ${pollutantLabel(im.pollutant)}`],
    ["95% confidence interval", `${im.ciLow}% to ${im.ciHigh > 0 ? "+" : ""}${im.ciHigh}%`],
    ["Duration", `${im.durationMin} min`],
    ["Method", "Synthetic control"],
    ["Donor cells", `${im.donorCells.length}, similar land use`],
  ];
  return (
    <div className="card flex flex-col overflow-hidden">
      <div className="flex flex-wrap items-center gap-2.5 border-b border-line px-4 py-3">
        <span className="text-[15px] font-semibold">#{iv.id} · {iv.asset} · {iv.place}</span>
        <span className="inline-flex items-center gap-[5px] whitespace-nowrap text-[13px] font-medium">
          {im.verdict === "Verified" ? <BadgeCheck size={14} /> : <CircleDashed size={14} />}{im.verdict}
        </span>
      </div>
      <div className="px-4 pb-1.5 pt-3.5">
        <ChartKey />
        <SyntheticControlChart impact={im} asset={iv.asset} />
      </div>
      <div className="grid min-h-[230px] flex-1 grid-cols-[minmax(0,1fr)_190px] border-t border-line">
        <div className="relative min-h-[230px]">
          <HawaMap mode="donor" layers={["hex"]} center={at ?? [77.316, 28.647]} zoom={12.8} interactive={false} donors={weights} />
          <MapBadge className="left-2.5 top-2.5 !h-auto !px-2 !py-[3px] !text-[12.5px] !font-normal">Donor cells and their weights</MapBadge>
        </div>
        <div className="flex flex-col gap-2.5 border-l border-line px-3.5 py-3">
          {facts.map(([k, v]) => (
            <div key={k} className="flex flex-col gap-px"><span className="text-[13px] text-muted">{k}</span><span className="text-sm font-medium">{v}</span></div>
          ))}
        </div>
      </div>
    </div>
  );
}
