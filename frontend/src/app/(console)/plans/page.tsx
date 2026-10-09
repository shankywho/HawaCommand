"use client";
// Plans index: open the pending plan for the ward, or offer to draft one
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { PlanEmpty, PlanSkeleton } from "@/components/plans/PlanStates";
import { Screen } from "@/components/shell/Screen";
import { useDraftPlan, usePlans } from "@/hooks/usePlan";
import { useConsole } from "@/stores/console";

export default function PlansIndex() {
  const router = useRouter();
  const ward = useConsole((s) => s.ward);
  const plans = usePlans();
  const draft = useDraftPlan((p) => router.push(`/plans/${p.id}`));
  const next = plans.data?.items.find((p) => p.ward === ward) ?? plans.data?.items[0];

  useEffect(() => {
    if (next) router.replace(`/plans/${next.id}`);
  }, [next, router]);

  return (
    <Screen headline={`Plans for ${ward}`}>
      <div className="min-h-0 flex-1 overflow-auto">
        {plans.isLoading || next ? <PlanSkeleton /> : <PlanEmpty ward={ward} onDraft={() => draft.mutate(ward)} />}
      </div>
    </Screen>
  );
}
