// right-hand drawer: reviewers + agents on this plan
import type { Plan } from "@hawa/contracts";
import { CircleCheck, MessageSquareWarning, X } from "lucide-react";
import { clock } from "@/lib/time";

export function PlanDetails({ plan, onClose }: { plan: Plan; onClose: () => void }) {
  const resolved = plan.comments.every((c) => c.status !== "open");
  const approved = plan.status === "approved";
  return (
    <div className="absolute inset-0 z-[5] flex animate-pin flex-col overflow-auto bg-white">
      <div className="flex items-center border-b border-line px-[18px] py-3.5">
        <span className="flex-1 text-base font-semibold">Details</span>
        <button onClick={onClose} aria-label="Close details" className="grid size-[30px] place-items-center rounded-md hover:bg-hover"><X size={16} /></button>
      </div>
      <div className="flex flex-col gap-2.5 border-b border-line px-[18px] py-3.5">
        <span className="text-[13.5px] text-muted">Reviewers</span>
        <div className="flex items-center gap-2.5 text-sm">
          <span className="grid size-[22px] place-items-center rounded-md bg-ink text-[10px] font-semibold text-white">AU</span>
          <span className="flex-1">Auditor agent</span>
          <span className="flex items-center gap-[5px]">{resolved ? <CircleCheck size={14} /> : <MessageSquareWarning size={14} />}{resolved ? "Resolved" : "Changes requested"}</span>
        </div>
        <div className="flex items-center gap-2.5 text-sm">
          <span className="grid size-[22px] place-items-center rounded-full bg-hover text-[10px] font-semibold">WO</span>
          <span className="flex-1">Ward officer (you)</span>
          <span className="text-muted">{approved && plan.approvedAt ? `Approved ${clock(plan.approvedAt)}` : "Awaiting you"}</span>
        </div>
      </div>
      <div className="flex flex-col gap-2.5 px-[18px] py-3.5 text-sm">
        <span className="text-[13.5px] text-muted">Agents on this plan</span>
        {[["Forecaster", `Forecast run ${clock(plan.draftedAt)}`], ["Planner", `${plan.groups.length} asset routes`], ["Auditor", `${plan.comments.length} comment${plan.comments.length === 1 ? "" : "s"}`]].map(([k, v]) => (
          <div key={k} className="flex flex-wrap justify-between gap-x-3 gap-y-1"><span>{k}</span><span className="text-muted">{v}</span></div>
        ))}
        <p className="m-0 mt-1.5 text-pretty text-[13.5px] leading-normal text-muted">Agents explain and critique. The optimiser enforces shift, capacity and cause–tool rules; agents cannot bypass them.</p>
      </div>
    </div>
  );
}
