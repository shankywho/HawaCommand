// checks + Request changes / Approve & dispatch -> POST approve, shows Step Functions status
import type { Plan } from "@hawa/contracts";
import { CircleAlert, CircleCheck, Send } from "lucide-react";

export function ApproveBar({ plan, onApprove, onRequestChanges, busy }: {
  plan: Plan; onApprove: () => void; onRequestChanges: () => void; busy?: boolean;
}) {
  const approved = plan.status === "approved" || plan.status === "dispatching" || plan.status === "done";
  const allOk = plan.checks.every((c) => c.ok);
  const title = approved
    ? "Approved. Routes and alerts are scheduled."
    : allOk ? "All checks passed. Ready for your approval." : `${plan.checks.filter((c) => !c.ok).length} check needs attention before dispatch.`;

  return (
    <div className="card mt-[18px] overflow-hidden">
      {plan.checks.map((c) => (
        <div key={c.id} className="flex flex-wrap items-center gap-2.5 border-b border-line-soft px-3.5 py-[11px] text-[14.5px]">
          <span className={c.ok ? "text-ink" : "text-danger"}>{c.ok ? <CircleCheck size={16} /> : <CircleAlert size={16} />}</span>
          <span className={`flex-1 ${c.ok ? "" : "font-semibold"}`}>{c.label}</span>
          <span className="text-sm text-muted">{c.detail}</span>
        </div>
      ))}
      <div className="flex flex-wrap items-center gap-3 bg-paper p-3.5">
        <div className="flex min-w-[240px] flex-1 flex-col gap-0.5">
          <span className="text-[15px] font-semibold">{title}</span>
          <span className="text-[13.5px] text-muted">
            {plan.executionArn ? <>Step Functions: <span className="font-mono text-xs">{plan.executionArn.split(":").at(-1)}</span></> : "Nothing dispatches without your approval. Routes go to drivers at 05:30."}
          </span>
        </div>
        {!approved && <button onClick={onRequestChanges} className="btn btn-lg btn-quiet">Request changes</button>}
        <button onClick={onApprove} disabled={busy || approved} className="btn btn-lg btn-primary disabled:cursor-default" style={{ opacity: allOk || approved ? 1 : 0.55 }}>
          <Send size={14} />{approved ? "Approved" : busy ? "Approving…" : "Approve & dispatch"}
        </button>
      </div>
    </div>
  );
}
