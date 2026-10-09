// confidence is always shown as a word, with the number on hover
import { clsx } from "clsx";
import { confidenceTitle, confidenceWord } from "@/lib/format";

export function Confidence({ value, suffix = "", dotted = false, className }: { value: number; suffix?: string; dotted?: boolean; className?: string }) {
  return (
    <span title={confidenceTitle(value)} className={clsx("cursor-help", dotted && "hint", className)}>
      {confidenceWord(value)}
      {suffix}
    </span>
  );
}
