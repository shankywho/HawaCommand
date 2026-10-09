"use client";
// SCREEN C Plan Review: hero metric, PR-style diff, Auditor comment, Approve & dispatch
import { use, useMemo, useState } from "react";
import { HawaMap, MapBadge } from "@/components/map/HawaMap";
import { ApproveBar } from "@/components/plans/ApproveBar";
import { PlanDetails } from "@/components/plans/PlanDetails";
import { PlanDiff } from "@/components/plans/PlanDiff";
import { PlanHeader } from "@/components/plans/PlanHeader";
import { PlannerNote } from "@/components/plans/PlannerNote";
import { PlanSkeleton } from "@/components/plans/PlanStates";
import { Screen } from "@/components/shell/Screen";
import { QueryError } from "@/components/ui/Skeleton";
import Link from "next/link";
import { ApiError } from "@/lib/api";
import { usePlan, usePlanActions } from "@/hooks/usePlan";
import { applyPlan, centroid, planReduction } from "@/components/map/layers";
import { useMapStations } from "@/components/map/useMapStations";
import { usePeakHour } from "@/hooks/usePeakHour";
import { windowLabel } from "@/lib/time";
import { useConsole } from "@/stores/console";
import { wardLabel } from "@/lib/format";

export default function PlanReviewPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const q = usePlan(id);
  const { applySuggestion, approve, requestChanges } = usePlanActions(id);
  const { thresholdUgm3, showToast } = useConsole();
  const [details, setDetails] = useState(false);
  const plan = q.data;
  const peak = usePeakHour();
  const base = useMapStations(peak);
  const stations = useMemo(() => applyPlan(base, planReduction(plan?.headline), thresholdUgm3), [base, plan, thresholdUgm3]);
  const top = base?.reduce((a, b) => (b.pm > a.pm ? b : a));

  const onApprove = () =>
    approve.mutate(undefined, {
      onSuccess: (p) => {
        const tasks = p.groups.flatMap((g) => g.tasks).filter((t) => t.op === "add").length;
        showToast({ title: `Plan #${p.id} approved`, body: `${tasks} tasks queued for ${windowLabel(p.window)}.` });
      },
    });

  return (
    <Screen
      headline={plan ? `Plan #${plan.id} for ${wardLabel(plan.ward)} is ${plan.status === "approved" ? "approved and dispatching" : "waiting for your approval"}.` : `Plan #${id}`}
      aside={
        <>
          <div className="relative min-h-[420px] flex-1">
            <HawaMap
              mode="plan"
              layers={["hex", "stations", "trucks", "schools"]}
              hour={peak}
              stations={stations}
              thresholdUgm3={thresholdUgm3}
              assets={["T-12", "ASG-07", "SW-03", "I-3"]}
              labels="sel"
              selected={top?.id}
              center={centroid(base) ?? [77.312, 28.64]}
              zoom={11.4}
            />
            <MapBadge className="left-2.5 top-2.5 !h-auto !px-[9px] !py-1 !text-[13px]">{plan ? `Plan routes · ${windowLabel(plan.window)}` : "Plan routes"}</MapBadge>
          </div>
          {details && plan && <PlanDetails plan={plan} onClose={() => setDetails(false)} />}
        </>
      }
    >
      <div className="min-h-0 flex-1 overflow-auto" data-screen-label="Plan review">
        {q.isLoading ? <PlanSkeleton /> : q.error instanceof ApiError && q.error.status === 404 ? (
          <div className="m-6 flex flex-col items-start gap-3 rounded-lg border border-line bg-white p-5 text-sm"><span className="text-base font-semibold">Plan not found</span><span className="text-muted">No plan with id {id}. It may have been cleared when the server restarted.</span><Link href="/plans" className="btn btn-md btn-quiet">Back to plans</Link></div>
        ) : q.error ? <QueryError error={q.error} /> : plan && (
          <div className="max-w-[1080px] px-[clamp(20px,2.4vw,40px)] pb-12 pt-[22px]">
            <PlanHeader plan={plan} onToggleDetails={() => setDetails(!details)} />
            <PlannerNote summary={plan.summary} reasoning={plan.reasoning} confidence={plan.headline.confidence} />
            <PlanDiff plan={plan} applying={applySuggestion.isPending} onApply={(c) => applySuggestion.mutate(c)} />
            <ApproveBar
              plan={plan}
              busy={approve.isPending}
              onApprove={onApprove}
              onRequestChanges={() => requestChanges.mutate("Officer requested changes")}
            />
          </div>
        )}
      </div>
    </Screen>
  );
}
