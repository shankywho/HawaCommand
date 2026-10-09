"use client";
// headline, honest CTAs, and a "right now" card fed by the same API as the console
import { pm25Band } from "@hawa/contracts";
import { ArrowDown, ArrowUpRight } from "lucide-react";
import Link from "next/link";
import { AqiChip } from "@/components/ui/AqiChip";
import { dayTime } from "@/lib/time";
import { Parallax } from "../Parallax";
import { useLandingAir } from "../live";
import { ConsoleCta } from "./ui";

const FACTS = ["500 m cells", "72 h forecast", "Every fix verified"];

export function Hero() {
  const { top, count, grap, simulated } = useLandingAir();
  return (
    <section id="top" data-screen-label="Hero" className="relative flex min-h-screen flex-col pt-[68px]">
      <div className="mx-auto grid w-full max-w-[1400px] flex-1 items-stretch gap-6 px-4 pt-3 lg:grid-cols-[minmax(0,640px)_minmax(520px,1fr)] lg:px-6 lg:pt-10">
        <div className="min-w-0 self-center rounded-lg border border-ink/[.08] bg-paper/95 p-6 shadow-[0_12px_40px_rgba(60,40,20,.18)] lg:p-10">
          <p style={{ animationDelay: "60ms" }} className="animate-[lineIn_1s_cubic-bezier(.2,.7,.2,1)_both] mb-5 mt-0 flex items-center gap-2 text-[13px] font-semibold uppercase tracking-[.09em] text-teal">
            <i className="size-1.5 animate-blink bg-teal" />For MCD and DPCC ward officers
          </p>
          <h1 className="mb-[26px] mt-0 text-[clamp(44px,4.4vw,64px)] font-semibold leading-[1.02] tracking-[-.04em]">
            <span style={{ animationDelay: "160ms" }} className="animate-[lineIn_1s_cubic-bezier(.2,.7,.2,1)_both] block text-balance">Delhi already owns the machines.</span>
            <span style={{ animationDelay: "300ms" }} className="animate-[lineIn_1s_cubic-bezier(.2,.7,.2,1)_both] block text-balance text-teal">We give them a brain.</span>
          </h1>
          <p style={{ animationDelay: "460ms" }} className="animate-[lineIn_1s_cubic-bezier(.2,.7,.2,1)_both] mb-8 mt-0 max-w-[560px] text-pretty text-[19px] leading-normal text-muted-3">
            HawaCommand finds hotspots street by street, sends sprinklers before the spike, and proves each fix worked.
          </p>
          <div style={{ animationDelay: "580ms" }} className="animate-[lineIn_1s_cubic-bezier(.2,.7,.2,1)_both] flex flex-wrap gap-2.5">
            <ConsoleCta />
            <a href="#how" className="flex h-11 items-center gap-2 whitespace-nowrap rounded-lg border border-line bg-white px-[18px] text-[15px] font-medium !text-ink no-underline shadow-[0_1px_2px_rgba(11,18,21,.06)] hover:border-[#C9C4B9]">
              <ArrowDown size={15} />See how it works
            </a>
          </div>
          <ul className="m-0 mt-8 flex list-none flex-wrap gap-x-5 gap-y-2 border-t border-line p-0 pt-5 text-sm text-muted-3">
            {FACTS.map((f) => (
              <li key={f} className="flex items-center gap-2"><i className="size-1.5 bg-teal" />{f}</li>
            ))}
          </ul>
        </div>
        <div className="relative flex min-h-[480px] min-w-0 flex-col justify-end overflow-x-clip lg:min-h-[560px]">
          <div className="absolute inset-0 [clip-path:inset(-45%_0_-25%_0)]">
          <Parallax speed={0.16} className="absolute inset-0">
            <vx-city haze="1" className="origin-[50%_58%] scale-[1.15] sm:scale-[1.3] lg:scale-[1.4]" style={{ position: "absolute", inset: "-6% -2% 12% -2%" }} />
          </Parallax>
          </div>
          {top && (
            <AqiChip place={top.ward} value={Math.round(top.pm25)} kind="pm25" size="sm" blink={false} className="absolute right-2 top-4" title={simulated ? "Demo data" : "Live data"} />
          )}
          {top && (
            <div className="relative z-[1] w-full self-end rounded-lg border border-ink/[.08] bg-paper/95 p-4 shadow-[0_12px_40px_rgba(60,40,20,.18)] lg:w-[340px]">
              <div className="mb-3 flex items-center justify-between text-xs">
                <span className="flex items-center gap-1.5 font-semibold uppercase tracking-[.09em] text-teal"><i className="size-1.5 animate-blink bg-teal" />Right now</span>
                <span className="text-muted-2">{simulated ? "Simulated data" : "Live data"}</span>
              </div>
              <dl className="m-0 grid grid-cols-3 gap-3">
                <div><dd className="m-0 text-[26px] font-semibold leading-none tracking-[-.03em]">{count}</dd><dt className="mt-1 text-xs text-muted-2">hotspots ranked</dt></div>
                <div><dd className="m-0 text-[26px] font-semibold leading-none tracking-[-.03em]">{Math.round(top.pm25)}</dd><dt className="mt-1 text-xs text-muted-2">worst µg/m³</dt></div>
                {grap && <div><dd className="m-0 text-[26px] font-semibold leading-none tracking-[-.03em]">{grap.stage}</dd><dt className="mt-1 text-xs text-muted-2">GRAP stage</dt></div>}
              </dl>
              <p className="mb-0 mt-3 text-pretty text-[13.5px] leading-normal text-muted-3">
                {top.place} is {pm25Band(top.pm25).toLowerCase()}.
                {grap && <> Stage {grap.stage} is {Math.round(grap.probability * 100)}% likely by {dayTime(grap.likelyAt)}.</>}
              </p>
              <Link href="/map" className="mt-3 inline-flex items-center gap-1 text-[13.5px] font-medium !text-teal no-underline hover:underline">
                Open it in the console<ArrowUpRight size={14} />
              </Link>
            </div>
          )}
        </div>
      </div>
      <px-skyline stage="0.05" seed="5" style={{ display: "block", height: 240, marginTop: -40 }} />
    </section>
  );
}
