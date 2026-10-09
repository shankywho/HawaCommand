"use client";
// four causes as panels: hover or tap one to open it, the others fold to a strip (stacked cards on small screens)
import { useEffect, useRef, useState } from "react";
import { SectionIntro } from "./ui";

const CAUSES = [
  { n: "01", name: "Road dust", hi: "सड़क की धूल", scene: "dust", stage: "0.2", signal: "High PM10 · low PM2.5/PM10 ratio · daytime · near roads or sites", fix: "Sprinkler, sweeper, site check" },
  { n: "02", name: "Traffic", hi: "गाड़ियों का धुआँ", scene: "traffic", stage: "0.25", signal: "High NO₂ + CO · rush hours · along corridors", fix: "Diversion advice, smoky-vehicle checks, alerts" },
  { n: "03", name: "Open burning", hi: "कचरा जलाना", scene: "burning", stage: "0.25", signal: "Sharp PM2.5 + VOC spike · night · fire point or photo", fix: "Inspection team to the suspect pin" },
  { n: "04", name: "Stubble smoke", hi: "पराली का धुआँ", scene: "stubble", stage: "0.3", signal: "City-wide PM2.5 rise · north-west wind · FIRMS fires upwind", fix: "No trucks. Protect people: alerts, windows shut" },
];

export function Causes() {
  const [open, setOpen] = useState(0);
  const ref = useRef<HTMLElement>(null);

  // on wide screens the section is pinned while you scroll, and the scroll position picks the open cause (like How it works)
  useEffect(() => {
    const on = () => {
      const el = ref.current;
      if (!el || !matchMedia("(min-width: 1024px)").matches) return;
      const r = el.getBoundingClientRect();
      const p = Math.min(0.999, Math.max(0, -r.top / Math.max(1, r.height - innerHeight)));
      setOpen(Math.floor(p * CAUSES.length));
    };
    on();
    addEventListener("scroll", on, { passive: true });
    addEventListener("resize", on);
    return () => { removeEventListener("scroll", on); removeEventListener("resize", on); };
  }, []);

  return (
    <section id="causes" ref={ref} data-screen-label="Causes" className="relative lg:h-[340vh]">
      <div className="mx-auto flex max-w-[1200px] flex-col px-6 pb-8 pt-16 max-lg:py-12 lg:sticky lg:top-0 lg:h-screen lg:pt-[84px]">
      <SectionIntro
        index={2}
        eyebrow="Four causes, four fixes"
        title="Water settles dust. It does nothing for smoke."
        body="Each hotspot is tagged with a likely cause and a suspect location upwind. The cause decides which team goes."
      />
      <div className="flex flex-col gap-3 lg:min-h-0 lg:flex-1 lg:flex-row">
        {CAUSES.map((c, i) => {
          const on = i === open;
          return (
            <button
              key={c.n}
              onFocus={() => setOpen(i)}
              onClick={() => setOpen(i)}
              aria-expanded={on}
              className={`group relative flex min-w-0 flex-col overflow-hidden rounded-lg border bg-white text-left transition-[flex-grow,box-shadow,border-color] duration-[800ms] ease-[cubic-bezier(.2,.7,.2,1)] ${on ? "border-ink/30 shadow-pop lg:flex-[6]" : "border-line lg:flex-[1]"} flex-1`}
            >
              <div className={`relative lg:absolute lg:inset-0 ${on ? "" : "lg:h-full"}`}>
                <px-scene kind={c.scene} stage={c.stage} style={{ display: "block", width: "100%", height: "100%", minHeight: 220 }} />
              </div>
              {/* folded: number and vertical name */}
              <div className={`pointer-events-none absolute inset-x-0 top-0 hidden items-center justify-between p-4 transition-opacity duration-500 lg:flex ${on ? "opacity-0" : "opacity-100"}`}>
                <span className="rounded bg-paper/90 px-1.5 py-0.5 font-mono text-[13px] text-ink">{c.n}</span>
              </div>
              <span className={`pointer-events-none absolute bottom-5 left-4 hidden origin-bottom-left -rotate-90 translate-x-[22px] whitespace-nowrap rounded bg-paper/90 px-2 py-0.5 text-xl font-medium tracking-[-.02em] text-ink transition-opacity duration-500 lg:block ${on ? "opacity-0" : "opacity-100"}`}>{c.name}</span>
              {/* open: details */}
              <div className={`relative flex flex-col gap-3 p-6 transition-all duration-700 lg:m-3 lg:mt-auto lg:w-[min(calc(100%-24px),600px)] lg:rounded-lg lg:bg-white/95 lg:p-6 lg:shadow-pop ${on ? "lg:translate-y-0 lg:opacity-100" : "lg:pointer-events-none lg:translate-y-4 lg:opacity-0"}`}>
                <div className="text-[13px] text-muted-2">Cause {c.n}</div>
                <div className="flex flex-wrap items-baseline gap-3">
                  <span className="text-[clamp(28px,3vw,44px)] font-semibold leading-none tracking-[-.03em]">{c.name}</span>
                  <span className="font-deva text-lg font-medium text-muted-2">{c.hi}</span>
                </div>
                <div className="rounded-md bg-hover px-3 py-2 text-[13.5px] leading-normal text-muted-3 ">{c.signal}</div>
                <div className="flex flex-col gap-1 border-t border-dashed border-line pt-3 ">
                  <span className="text-[13px] font-medium text-teal">Fix</span>
                  <span className="text-[16px] leading-[1.45]">{c.fix}</span>
                </div>
              </div>
            </button>
          );
        })}
      </div>
      </div>
    </section>
  );
}
