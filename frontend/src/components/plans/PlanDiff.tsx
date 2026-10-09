// task rows with +/- vs usual route, reason text
import type { Plan } from "@hawa/contracts";
import { MessageSquareWarning } from "lucide-react";
import { CauseTag } from "@/components/ui/CauseTag";
import { ASSET_ICON } from "@/components/ui/icons";
import { AuditorComment } from "./AuditorComment";

export function PlanDiff({ plan, onApply, applying }: { plan: Plan; onApply: (commentId: string) => void; applying?: boolean }) {
  const commentFor = (taskId: string) => plan.comments.find((c) => c.taskId === taskId);
  const applied = plan.comments.every((c) => c.status !== "open");

  return (
    <div className="flex flex-col gap-3">
      {plan.groups.map((g) => {
        // Suggested tasks only appear once the officer accepts the Auditor's suggestion.
        const tasks = g.tasks.filter((t) => !(t.flag === "suggested" && !applied));
        const add = tasks.filter((t) => t.op === "add").length;
        const Icon = ASSET_ICON[g.kind];
        return (
          <div key={g.asset} className="card overflow-hidden">
            <div className="flex items-center gap-2.5 border-b border-line bg-paper px-3.5 py-2.5">
              <Icon size={15} />
              <span className="text-sm font-semibold">{g.asset}</span>
              <span className="text-sm text-muted">{g.label}</span>
              <div className="flex-1" />
              <span className="text-[13px] font-medium">+{add}</span>
              <span className="text-[13px] text-muted">−{tasks.length - add}</span>
            </div>
            {tasks.map((t) => {
              const isAdd = t.op === "add";
              const comment = commentFor(t.id);
              const flagged = t.flag === "suggested" || (comment?.status === "open");
              return (
                <div key={t.id}>
                  <div className={`grid grid-cols-[30px_82px_minmax(0,1fr)] border-b border-line-soft ${isAdd ? "bg-white shadow-add" : "bg-paper"}`}>
                    <span className={`pl-[13px] pt-[11px] text-[15px] font-semibold ${isAdd ? "text-ink" : "text-muted"}`}>{isAdd ? "+" : "−"}</span>
                    <span className="whitespace-nowrap pt-[13px] font-mono text-[13px] text-muted">{t.time}</span>
                    <div className="flex min-w-0 flex-col gap-[5px] py-2.5 pr-3.5">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className={`text-[15px] font-medium decoration-muted decoration-1 ${isAdd ? "text-ink" : "text-muted line-through"}`}>{t.place}</span>
                        {t.cause && <CauseTag cause={t.cause} conf={t.causeConf} />}
                        {flagged && (
                          <span className="inline-flex h-[22px] items-center gap-[5px] whitespace-nowrap rounded-[5px] border border-ink px-2 text-[12.5px] font-medium">
                            <MessageSquareWarning size={12} />
                            {t.flag === "suggested" ? "From Auditor suggestion" : "1 review comment"}
                          </span>
                        )}
                      </div>
                      <span className="text-pretty text-sm leading-normal text-muted">{t.reason}</span>
                    </div>
                  </div>
                  {comment && <AuditorComment comment={comment} applying={applying} onApply={() => onApply(comment.id)} />}
                </div>
              );
            })}
          </div>
        );
      })}
    </div>
  );
}
