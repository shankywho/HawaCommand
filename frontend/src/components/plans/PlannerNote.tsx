"use client";
import { ChevronDown, ChevronUp } from "lucide-react";
import { useState } from "react";
import { Confidence } from "@/components/ui/Confidence";

export function PlannerNote({ summary, reasoning, confidence }: { summary: string; reasoning: string; confidence: number }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="mb-[18px] flex gap-3">
      <span className="grid size-8 flex-none place-items-center rounded-lg border border-line bg-hover text-[11px] font-semibold">PL</span>
      <div className="card min-w-0 flex-1 overflow-hidden">
        <div className="border-b border-line px-3.5 py-[9px] text-sm text-muted">
          <b className="font-medium text-ink">Planner agent</b> · <Confidence value={confidence} suffix=" confidence" dotted />
        </div>
        <p className="m-0 text-pretty px-3.5 pb-2 pt-3 text-[15px] leading-[1.6]">{summary}</p>
        {open && <p className="m-0 text-pretty px-3.5 pb-2 text-[14.5px] leading-[1.6] text-muted">{reasoning}</p>}
        <button onClick={() => setOpen(!open)} className="mx-3.5 mb-3 flex items-center gap-1 text-[13.5px] font-medium underline decoration-line-strong underline-offset-[3px] hover:decoration-ink">
          {open ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
          {open ? "Hide reasoning" : "Show reasoning"}
        </button>
      </div>
    </div>
  );
}
