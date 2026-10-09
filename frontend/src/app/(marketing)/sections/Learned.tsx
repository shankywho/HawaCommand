// China/Japan lessons as an editorial list + the smog-tower refusal
import { Reveal } from "../Reveal";
import { Section, SectionIntro } from "./ui";

const CARDS = [
  { scene: "grid", cc: "CN", title: "Hotspot grid", body: "Beijing–Tianjin–Hebei split into 3×3 km blocks. In the Cangzhou pilot, PM2.5 fell 38.3% vs about 20% city average.", feature: "F1 · Hotspot Grid Engine" },
  { scene: "taxi", cc: "CN", title: "Taxi sensor networks", body: "Shanghai put sensors on 125 taxis. 80–100 of them covered about 80% of major roads at ~200 m.", feature: "F2 · Mobile sensing fleet" },
  { scene: "alerts", cc: "CN", title: "Graded response", body: "Blue to red alerts issued at least 24 h ahead, each level triggering preset emission cuts.", feature: "F6 · Graded Response Copilot" },
  { scene: "opendata", cc: "JP", title: "Open data, AEROS", body: "Real-time readings from every station, published openly. Open data built public trust.", feature: "F21 · Open Air Data portal" },
];

export function Learned() {
  return (
    <Section id="learned" label="Learned" className="!pt-28">
      <SectionIntro
        index={7}
        eyebrow="Learned from China and Japan"
        title="What we copied from Beijing, Shanghai and Tokyo, and what we didn't"
        body="China and Japan fought severe urban air before India did. We copy their data and governance systems, not their purifier hardware."
      />
      <ul className="m-0 list-none rounded-lg border border-ink/[.08] bg-paper/95 p-0">
        {CARDS.map((p, i) => (
          <li key={p.title} className="border-t border-ink/10 first:border-t-0">
            <Reveal delay={i * 90} from="left">
              <div className="group grid items-center gap-5 px-6 py-7 transition-colors duration-300 hover:bg-white lg:grid-cols-[84px_minmax(0,1fr)_minmax(0,1.1fr)_300px] lg:gap-10 lg:px-10">
                <span className="font-mono text-sm text-muted-2">{String(i + 1).padStart(2, "0")} · {p.cc}</span>
                <h3 className="m-0 text-[clamp(26px,2.6vw,40px)] font-semibold leading-[1.05] tracking-[-.03em] transition-transform duration-500 group-hover:translate-x-2">{p.title}</h3>
                <div className="flex flex-col gap-2">
                  <p className="m-0 text-pretty text-[15.5px] leading-[1.55] text-muted-3">{p.body}</p>
                  <span className="text-[13px] text-teal">{p.feature}</span>
                </div>
                <div className="overflow-hidden rounded-md">
                  <px-scene kind={p.scene} stage="0.75" style={{ display: "block", aspectRatio: "96/56", transition: "transform .7s cubic-bezier(.2,.7,.2,1)" }} className="origin-center group-hover:scale-[1.06]" />
                </div>
              </div>
            </Reveal>
          </li>
        ))}
      </ul>
      <div className="mt-3 flex flex-wrap items-center gap-x-8 gap-y-3 rounded-lg border border-dashed border-ink bg-hover p-3">
        <div className="min-w-[200px] flex-[0_1_300px]"><px-scene kind="tower" stage="0.75" style={{ display: "block", aspectRatio: "96/56", borderRadius: 4, overflow: "hidden" }} /></div>
        <div className="flex flex-[1_1_320px] flex-col gap-1.5 px-2.5 py-1.5">
          <div className="text-sm font-medium text-muted">What we refused to copy</div>
          <div className="text-[clamp(28px,3vw,44px)] font-medium tracking-[-.03em] line-through decoration-[3px]">Smog towers</div>
          <div className="max-w-[620px] text-pretty text-[15px] leading-[1.55] text-muted-3">Measured effect fell to about 12–16% beyond 100–200 m. The Connaught Place tower cost about ₹20 crore to build.</div>
        </div>
      </div>
    </Section>
  );
}
