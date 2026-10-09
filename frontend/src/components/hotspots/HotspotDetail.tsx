// 4 blocks: headline, value+cause, who's affected, primary action; forecast below
import { addHours, dayTime, now } from "@/lib/time";
import type { Hotspot } from "@hawa/contracts";
import { bandColor, pm25BandIndex } from "@hawa/contracts";
import { ChevronLeft } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useDraftPlan, usePlans } from "@/hooks/usePlan";
import { useConsole } from "@/stores/console";
import { ForecastChart } from "@/components/charts/ForecastChart";
import { Fact } from "@/components/shell/Screen";
import { CauseTag } from "@/components/ui/CauseTag";
import { Confidence } from "@/components/ui/Confidence";
import { CAUSE_VERB, fmtInt, wardLabel } from "@/lib/format";

export function HotspotDetail({ h, hour, onBack }: { h: Hotspot; hour: number; onBack: () => void }) {
  const router = useRouter();
  const ward = useConsole((s) => s.ward);
  const showToast = useConsole((s) => s.showToast);
  const planId = usePlans().data?.items[0]?.id;
  const draft = useDraftPlan((p) => {
    showToast({ title: `Draft plan #${p.id} created`, body: "Review it before anything is dispatched." });
    router.push(`/plans/${p.id}`);
  });
  const bi = pm25BandIndex(h.pm25);
  const c = bandColor(bi);
  return (
    <>
      <div className="flex flex-col gap-2.5 border-b border-line px-[18px] pb-4 pt-3.5">
        <button onClick={onBack} className="flex h-[26px] items-center gap-1 self-start whitespace-nowrap pl-0.5 pr-1.5 text-[13.5px] text-muted hover:text-ink">
          <ChevronLeft size={15} />All hotspots
        </button>
        <div className="flex flex-col gap-0.5">
          <span className="text-pretty text-xl font-semibold leading-tight tracking-[-.02em]">{h.placeFull ?? h.place}</span>
          <span className="text-[13.5px] text-muted">{wardLabel(h.ward)}</span>
        </div>
        <div className="flex flex-wrap items-baseline gap-2">
          <span className="text-[40px] font-semibold leading-none tracking-[-.03em]">{h.pm25}</span>
          <span className="text-sm text-muted">µg/m³ PM2.5</span>
        </div>
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="inline-flex h-[26px] items-center gap-1.5 whitespace-nowrap rounded-md px-[9px] text-[13px] font-medium" style={{ background: `${c}1A` }}>
            <i className="size-[9px] rounded-sm" style={{ background: c }} />
            {h.band}
          </span>
          <CauseTag cause={h.cause} conf={h.causeConf} size="md" />
        </div>
      </div>

      <div className="flex flex-col border-b border-line px-[18px] py-1.5">
        <Fact k="Exposure, next 4 h">{fmtInt(h.exposurePh)} people-hours</Fact>
        <Fact k="Rank in Delhi">#{h.rank}</Fact>
        <div className="fact-row">
          <span className="text-muted">Estimate confidence</span>
          <Confidence value={h.conf} className="font-medium" />
        </div>
      </div>

      <div className="flex items-start gap-2.5 border-b border-line px-[18px] py-3.5">
        <span className="mt-[5px] size-2.5 flex-none rotate-45 border-[1.5px] border-ink" />
        <div className="flex flex-col gap-0.5">
          <span className="text-[13.5px] text-muted">Likely source upwind</span>
          <span className="text-[14.5px] font-medium">{h.suspectPin.label}</span>
          {h.suspectPin.distanceKm !== undefined && (
            <span className="text-[13.5px] text-muted">
              {h.suspectPin.distanceKm} km {h.suspectPin.bearing} · about {h.suspectPin.travelMin} min away on this wind
            </span>
          )}
        </div>
      </div>

      <div className="flex flex-col gap-2 border-b border-line px-[18px] py-3.5">
        <span className="text-[13.5px] text-muted">Schools nearby · assembly at 08:00</span>
        {h.schools.map((s) => (
          <div key={s.id} className="flex items-center gap-2.5 text-sm">
            <span className="grid size-4 place-items-center rounded-[3px] border border-ink text-[8px] font-semibold">S</span>
            <span className="flex-1">{s.name}</span>
            <span className="whitespace-nowrap text-muted">{s.distanceKm} km</span>
          </div>
        ))}
      </div>

      {h.forecast && (
        <div className="border-b border-line px-[18px] py-3.5">
          <div className="mb-2 flex flex-wrap justify-between gap-2 text-[13.5px] text-muted"><span>72-hour forecast</span><span>Peak {dayTime(addHours(now(), h.forecast.reduce((a, b) => (b.p50 > a.p50 ? b : a)).h))}</span></div>
          <ForecastChart series={h.forecast} hour={Math.max(0, hour)} />
        </div>
      )}

      <div className="flex flex-wrap gap-2 px-[18px] py-3.5">
        <button
          onClick={() => draft.mutate(ward)}
          disabled={draft.isPending}
          title="Drafts a plan for review. Nothing is dispatched until you approve it."
          className="btn btn-lg btn-primary flex-auto disabled:cursor-default disabled:opacity-70"
        >
          {draft.isPending ? "Drafting…" : CAUSE_VERB[h.cause]}
        </button>
        {planId && <Link href={`/plans/${planId}`} className="btn btn-lg btn-quiet flex-auto">Open Plan #{planId}</Link>}
      </div>
    </>
  );
}
