// HawaPod exploded view + BOM
import { Section, SectionIntro } from "./ui";

const SPECS = [
  ["Controller", "ESP32-S3, TinyML spike detector"],
  ["Particles", "Plantower PMS5003 · PM1 / PM2.5 / PM10"],
  ["Gases", "MiCS-6814 via ADS1115 · NO₂, CO, NH₃"],
  ["Weather", "BME680 · T, RH, pressure, VOC"],
  ["Position", "u-blox NEO-M8N GPS"],
  ["Uplink", "A7670C 4G · MQTT over TLS · 72 h SD buffer"],
];

const Small = ({ kind, name, price, body }: { kind: string; name: string; price: React.ReactNode; body: string }) => (
  <div className="grid grid-cols-2 overflow-hidden rounded-lg border border-line bg-white">
    <div className="relative min-h-[220px] bg-paper"><vx-model kind={kind} style={{ position: "absolute", inset: 0 }} /></div>
    <div className="flex flex-col gap-2 p-5">
      <div className="text-xl font-semibold tracking-[-.01em]">{name}</div>
      <div className="text-sm font-medium">{price}</div>
      <p className="m-0 text-sm leading-normal text-muted-3">{body}</p>
    </div>
  </div>
);

export function Hardware() {
  return (
    <Section id="hardware" label="Hardware">
      <SectionIntro
        index={6}
        side="right"
        eyebrow="Hardware"
        title="The sensors, and what each one costs"
        body="Low-cost sensors ride on vehicles already moving through the city. For the demo, a simulator emits the exact same MQTT packets, so a real pod plugs in with no cloud change."
      />
      <div className="mb-3 grid overflow-hidden rounded-lg border border-line bg-white [grid-template-columns:repeat(auto-fit,minmax(min(100%,420px),1fr))]">
        <div className="relative min-h-[520px] border-r border-line bg-paper">
          <vx-pod scrub="" style={{ position: "absolute", inset: 0 }} />
          <span className="absolute left-5 top-5 text-[13px] text-muted-2">Scroll to take it apart</span>
        </div>
        <div className="flex flex-col gap-4 p-8">
          <div className="flex flex-wrap items-baseline justify-between gap-3"><div className="text-[28px] font-semibold tracking-[-.02em]">HawaPod-M</div><span className="text-base font-medium">₹7,000–9,500</span></div>
          <p className="m-0 text-[15px] leading-[1.55] text-muted-3">Rides on buses, e-rickshaws and delivery bikes. Street-level PM, gases, weather and GPS. A tiny on-device model flags spikes and publishes them instantly.</p>
          <div className="flex flex-col">
            {SPECS.map(([k, v]) => (
              <div key={k} className="grid grid-cols-[120px_minmax(0,1fr)] gap-3 border-b border-[#F0EEE9] py-2.5 text-sm"><span className="text-[13px] text-muted-2">{k}</span><span>{v}</span></div>
            ))}
          </div>
        </div>
      </div>
      <div className="grid gap-3 [grid-template-columns:repeat(auto-fit,minmax(min(100%,420px),1fr))]">
        <Small kind="pod-s" name="HawaPod-S" price={<>₹4,500 <span className="text-muted-2">+ ₹2,500 CO₂</span></>} body="A school pair: gate and classroom. Indoor unit adds an NDIR CO₂ sensor, so the school knows when to seal windows and when to ventilate." />
        <Small kind="tag" name="HawaTag" price="≈ ₹6,000" body="Fits sprinklers and smog guns. Water-flow and pump-current sensors prove spraying happened, not just driving. Cab-roof PM sensor captures before and after." />
      </div>
    </Section>
  );
}
