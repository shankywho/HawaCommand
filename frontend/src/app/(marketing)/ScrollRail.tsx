"use client";
// fixed left rail: numbered section dots with a scroll-progress line, visible on wide screens only
import { useEffect, useRef, useState } from "react";

const ITEMS = [["problem", "Problem"], ["causes", "Causes"], ["how", "How it works"], ["whatif", "What-if"], ["proof", "Proof"], ["hardware", "Hardware"], ["learned", "Learned"], ["aws", "AWS"]] as const;

export function ScrollRail() {
  const fill = useRef<HTMLElement>(null);
  const [active, setActive] = useState(-1);

  useEffect(() => {
    let raf = 0;
    const on = () => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        const first = document.getElementById(ITEMS[0][0]);
        const last = document.getElementById(ITEMS[ITEMS.length - 1]![0]);
        if (!first || !last) return;
        const a = first.getBoundingClientRect().top + scrollY;
        const b = last.getBoundingClientRect().bottom + scrollY - innerHeight;
        const p = Math.min(1, Math.max(0, (scrollY - a) / Math.max(1, b - a)));
        if (fill.current) fill.current.style.transform = `scaleY(${p.toFixed(4)})`;
        let idx = -1;
        ITEMS.forEach(([id], i) => { const e = document.getElementById(id); if (e && e.getBoundingClientRect().top < innerHeight * 0.45) idx = i; });
        setActive((o) => (o === idx ? o : idx));
      });
    };
    on();
    addEventListener("scroll", on, { passive: true });
    addEventListener("resize", on);
    return () => { removeEventListener("scroll", on); removeEventListener("resize", on); cancelAnimationFrame(raf); };
  }, []);

  return (
    <nav aria-label="Page sections" className="pointer-events-none fixed left-[18px] top-1/2 z-10 hidden -translate-y-1/2 min-[1360px]:block">
      <div className="relative flex flex-col gap-[18px] py-1">
        <span className="absolute bottom-3 left-[11px] top-3 w-px bg-ink/15" />
        <i ref={fill as React.RefObject<HTMLElement>} className="absolute bottom-3 left-[11px] top-3 w-px origin-top bg-teal" style={{ transform: "scaleY(0)" }} />
        {ITEMS.map(([id, label], i) => {
          const on = i === active;
          return (
            <a key={id} href={`#${id}`} className="group pointer-events-auto relative flex items-center gap-2.5 no-underline">
              <span className={`relative z-[1] grid size-[23px] place-items-center rounded-full border font-mono text-[10px] font-medium transition-all duration-300 ${on ? "scale-110 border-teal bg-teal text-white" : i < active ? "border-teal bg-paper text-teal" : "border-ink/20 bg-paper text-muted-2 group-hover:border-teal"}`}>{String(i + 1).padStart(2, "0")}</span>
              <span className={`whitespace-nowrap rounded-md border border-ink/10 bg-paper/95 px-2 py-[3px] text-[12.5px] font-medium !text-ink shadow-pop transition-all duration-300 ${on ? "translate-x-0 opacity-100" : "-translate-x-2 opacity-0 group-hover:translate-x-0 group-hover:opacity-100"}`}>{label}</span>
            </a>
          );
        })}
      </div>
    </nav>
  );
}
