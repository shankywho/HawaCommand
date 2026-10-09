// '+31% more people protected with the same fleet'
import type { Plan } from "@hawa/contracts";
import { Columns2, GitPullRequestDraft, PanelRight, Pencil } from "lucide-react";
import Link from "next/link";
import { CountUp } from "@/components/ui/CountUp";
import { Confidence } from "@/components/ui/Confidence";
import { clock, windowLabel } from "@/lib/time";
import { fmtInt, fmtRange } from "@/lib/format";

const STATUS: Record<Plan["status"], string> = {
  drafting: "Drafting",
  draft: "Draft",
  changes_requested: "Changes requested",
  approved: "Approved · dispatching",
  dispatching: "Dispatching",
  done: "Done",
};

export function PlanHeader({ plan, onToggleDetails }: { plan: Plan; onToggleDetails: () => void }) {
  const h = plan.headline;
  return (
    <>
      <div className="mb-4 flex flex-wrap items-center gap-2.5">
        <span className="inline-flex h-[26px] items-center gap-1.5 whitespace-nowrap rounded-full border border-line bg-white px-2.5 text-[13px] font-medium">
          <GitPullRequestDraft size={13} />{STATUS[plan.status]}
        </span>
        <span className="min-w-[220px] flex-1 text-sm text-muted">
          {windowLabel(plan.window)} · drafted by the {plan.draftedBy} at {clock(plan.draftedAt)}
        </span>
        <div className="flex gap-1.5">
          <button disabled title="Plan editing is not available yet" className="btn btn-md btn-quiet disabled:cursor-not-allowed disabled:opacity-50"><Pencil size={14} />Edit</button>
          <Link href="/what-if" className="btn btn-md btn-quiet"><Columns2 size={14} />Compare</Link>
          <button onClick={onToggleDetails} className="btn btn-md btn-quiet"><PanelRight size={14} />Details</button>
        </div>
      </div>

      <div className="card mb-[18px] flex flex-col gap-2 px-6 py-[22px]">
        <div className="text-balance text-[30px] font-semibold leading-[1.2] tracking-[-.025em]">
          <CountUp to={h.protectedPct} prefix="+" suffix="%" /> more people protected with the same fleet
        </div>
        <div className="text-pretty text-[14.5px] leading-normal text-muted">
          {fmtInt(h.peopleHoursSaved)} fewer people-hours of exposure than the usual routes, using {h.assetsUsed} of {h.assetsTotal} existing assets ·{" "}
          <span title={`Model confidence ${h.confidence.toFixed(2)} · likely range ${fmtRange(h.likelyRange)}`} className="hint text-ink">
            <Confidence value={h.confidence} suffix=" confidence" className="!cursor-help" />
          </span>
        </div>
      </div>
    </>
  );
}
