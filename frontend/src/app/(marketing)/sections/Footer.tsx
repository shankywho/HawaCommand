// clean-sky footer, open data link
import { Braces } from "lucide-react";
import { AqiChip } from "@/components/ui/AqiChip";
import { API_URL } from "@/lib/api";
import { ConsoleCta } from "./ui";

const OPEN_PATH = "/open/v1/air";

export function Footer() {
  return (
    <footer id="open" data-screen-label="Footer" className="relative pt-[120px]">
      <div className="mx-auto flex max-w-[760px] flex-col items-center gap-5 px-6 text-center">
        <AqiChip place="Our target" value={48} kind="aqi" size="lg" blink={false} className="!bg-[#1B7F45]" title="A target for Delhi, not a current reading" />
        <div className="flex flex-col items-center gap-5 rounded-lg border border-ink/[.08] bg-paper/95 px-8 py-10">
          <h2 className="m-0 text-balance text-[clamp(34px,4.4vw,56px)] font-semibold leading-[1.02] tracking-[-.04em]">Watch a plan get drafted, checked and approved.</h2>
          <div className="flex flex-wrap justify-center gap-2.5">
            <ConsoleCta />
            {API_URL ? (
              <a href={`${API_URL}${OPEN_PATH}`} target="_blank" rel="noopener noreferrer" className="flex h-11 items-center gap-2 whitespace-nowrap rounded-lg border border-line bg-white px-[18px] text-[15px] font-medium !text-ink no-underline hover:border-[#C9C4B9]"><Braces size={15} />GET {OPEN_PATH}</a>
            ) : (
              <span title="Available when the page is connected to the backend" className="flex h-11 items-center gap-2 whitespace-nowrap rounded-lg border border-dashed border-line bg-white/70 px-[18px] text-[15px] font-medium text-muted-2"><Braces size={15} />GET {OPEN_PATH}</span>
            )}
          </div>
        </div>
      </div>
      <px-skyline stage="1" seed="5" style={{ display: "block", height: 260, marginTop: 40 }} />
      <div className="border-t border-line bg-paper">
        <div className="mx-auto flex max-w-[1200px] flex-wrap justify-between gap-4 p-6 text-[13px] text-muted-2">
          <span className="flex flex-col gap-1"><span>HawaCommand · Environmental Hacks 2026 · Air track</span><span>Demo runs on simulated sensors, station history and interventions. Ingestion for CPCB, OpenAQ, NASA FIRMS and Open-Meteo is built.</span></span>
          <span className="flex flex-wrap gap-5">
            {[["#causes", "Product"], ["#how", "How it works"], ["#proof", "Proof"], ["#hardware", "Hardware"], ...(API_URL ? [[`${API_URL}${OPEN_PATH}`, "Open data (API)"]] : [])].map(([h, l]) => (
              <a key={l} href={h} className="!text-muted-2 no-underline hover:!text-ink">{l}</a>
            ))}
          </span>
        </div>
      </div>
    </footer>
  );
}
