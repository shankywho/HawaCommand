import type { Cause } from "@hawa/contracts";
import { clsx } from "clsx";
import { confidenceTitle, confidenceWord } from "@/lib/format";
import { CAUSE_ICON } from "./icons";

export function CauseTag({ cause, conf, size = "sm", className }: { cause: Cause; conf?: number; size?: "sm" | "md"; className?: string }) {
  const Icon = CAUSE_ICON[cause];
  return (
    <span
      title={conf !== undefined ? confidenceTitle(conf) : undefined}
      className={clsx(
        "inline-flex cursor-help items-center whitespace-nowrap bg-hover text-ink",
        size === "sm" ? "h-[22px] gap-[5px] rounded-[5px] px-2 text-[12.5px]" : "h-[26px] gap-1.5 rounded-md px-[9px] text-[13px]",
        className,
      )}
    >
      <Icon size={size === "sm" ? 12 : 13} strokeWidth={1.75} />
      {cause}
      {conf !== undefined && ` · ${confidenceWord(conf)}${size === "md" ? " confidence" : ""}`}
    </span>
  );
}
