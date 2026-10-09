// loading + empty states for Plan Review
import { GitPullRequest, Loader } from "lucide-react";
import { Skeleton } from "@/components/ui/Skeleton";

export function PlanSkeleton() {
  return (
    <div className="flex max-w-[1080px] flex-col gap-3.5 px-[clamp(20px,2.4vw,40px)] py-[22px]">
      <Skeleton className="h-[26px] w-2/5 rounded-md" />
      <div className="card h-[104px]" />
      <div className="flex items-center gap-2.5 text-sm text-muted"><Loader size={15} className="animate-spin" />Solving routes for 9 assets across 41 candidate cells, then Auditor review</div>
      <div className="card flex flex-col gap-2.5 p-3.5">
        <Skeleton className="h-3 w-4/5" /><Skeleton className="h-3 w-2/3" delay={0.15} /><Skeleton className="h-3 w-[72%]" delay={0.3} />
      </div>
    </div>
  );
}

export function PlanEmpty({ ward, onDraft }: { ward: string; onDraft: () => void }) {
  return (
    <div className="flex h-full items-center justify-center p-6">
      <div className="card flex w-[480px] max-w-full flex-col items-center gap-2.5 px-8 py-10 text-center">
        <span className="grid size-10 place-items-center rounded-lg border border-line text-muted"><GitPullRequest size={18} /></span>
        <div className="text-[17px] font-semibold">No draft plans for {ward}</div>
        <div className="max-w-[360px] text-pretty text-[14.5px] leading-normal text-muted">You can draft one now from the latest forecast and hotspot data.</div>
        <div className="mt-2 flex gap-2">
          <button onClick={onDraft} className="btn btn-primary h-[34px] px-[13px] text-sm">Draft plan now</button>
        </div>
      </div>
    </div>
  );
}
