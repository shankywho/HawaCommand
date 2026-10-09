// shared landing building blocks
import { ArrowUpRight } from "lucide-react";
import Link from "next/link";
import { Reveal } from "../Reveal";

export const CONSOLE_HREF = "/map";

export function SectionIntro({ eyebrow, title, body, index, side = "left" }: { eyebrow: string; title: React.ReactNode; body: React.ReactNode; index?: number; side?: "left" | "right" }) {
  const right = side === "right";
  return (
    <div className="mb-3">
      {/* the panel bleeds to the viewport edge on its side, so the section is anchored left or right instead of floating in the middle */}
      <div
        className={`grid w-full items-end gap-x-14 gap-y-5 rounded-lg border border-ink/[.08] bg-paper/95 p-7 lg:grid-cols-[minmax(0,1.3fr)_minmax(0,1fr)] lg:p-10 ${
          right ? "" : ""
        }`}
      >
        <div>
          <div className="mb-4 flex items-center gap-2.5 text-[12.5px] font-semibold uppercase tracking-[.09em] text-teal">
            {index != null && <span className="font-mono tracking-normal">{String(index).padStart(2, "0")}</span>}
            <i className="h-px w-8 bg-teal" />{eyebrow}
          </div>
          <h2 className="m-0 text-balance text-[clamp(32px,3.6vw,48px)] font-semibold leading-[1.02] tracking-[-.035em]">{title}</h2>
        </div>
        <p className="m-0 text-pretty text-[17px] leading-[1.6] text-muted-3">{body}</p>
      </div>
    </div>
  );
}

export function Section({ id, label, children, className = "" }: { id: string; label: string; children: React.ReactNode; className?: string }) {
  return (
    <section id={id} data-screen-label={label} className={`mx-auto max-w-[1200px] px-6 py-12 ${className}`}>
      <Reveal>{children}</Reveal>
    </section>
  );
}

export function ConsoleCta({ size = "lg" }: { size?: "md" | "lg" }) {
  return (
    <Link
      href={CONSOLE_HREF}
      className={`flex items-center whitespace-nowrap rounded-lg bg-ink font-medium !text-paper no-underline transition-colors hover:bg-ink-2 ${size === "lg" ? "h-11 gap-2 px-[18px] text-[15px]" : "h-9 gap-1.5 px-3.5 text-sm hover:!bg-teal hover:!text-white"}`}
    >
      Open live console<ArrowUpRight size={size === "lg" ? 16 : 15} />
    </Link>
  );
}
