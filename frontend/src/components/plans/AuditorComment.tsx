// objection + suggested change + Apply suggestion
import type { AuditorComment as Comment } from "@hawa/contracts";
import { Check } from "lucide-react";
import { Confidence } from "@/components/ui/Confidence";

export function AuditorComment({ comment, onApply, applying }: { comment: Comment; onApply: () => void; applying?: boolean }) {
  return (
    <div className="border-b border-line-soft bg-paper py-3 pl-11 pr-3.5 pb-3.5">
      <div className="overflow-hidden rounded-lg border border-line bg-white">
        <div className="flex flex-wrap items-center gap-2 border-b border-line px-3 py-[9px] text-sm text-muted">
          <span className="grid size-[22px] place-items-center rounded-md bg-ink text-[10px] font-semibold text-white">AU</span>
          <b className="font-medium text-ink">Auditor agent</b>
          {comment.status === "open" ? "requested changes" : "comment resolved"}
          <div className="flex-1" />
          <Confidence value={comment.confidence} suffix=" confidence" className="text-[13px]" />
        </div>
        <p className="m-0 p-3 text-[15px] leading-[1.55]">{comment.objection}</p>
        <div className="mx-3 mb-3 overflow-hidden rounded-md border border-line text-sm">
          <div className="border-b border-line bg-paper px-2.5 py-[7px] text-[13px] text-muted">Suggested change</div>
          <div className="px-2.5 py-[7px] text-muted line-through decoration-muted">− {comment.suggestion.remove}</div>
          <div className="px-2.5 py-[7px] shadow-add">+ {comment.suggestion.add}</div>
        </div>
        <div className="flex flex-wrap gap-2 px-3 pb-3">
          {comment.status === "open" ? (
            <button onClick={onApply} disabled={applying} className="btn btn-sm btn-outline">{applying ? "Applying…" : "Apply suggestion"}</button>
          ) : (
            <span className="flex h-[30px] items-center gap-1.5 whitespace-nowrap px-1 text-[13.5px] font-medium">
              <Check size={14} />Applied · Planner re-solved the routes
            </span>
          )}
          <button disabled title="Replying to the Auditor is not available yet" className="btn btn-sm btn-quiet disabled:cursor-not-allowed disabled:opacity-50">Reply</button>
        </div>
      </div>
    </div>
  );
}
