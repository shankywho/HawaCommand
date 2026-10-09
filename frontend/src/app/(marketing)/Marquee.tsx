// full-bleed ticker between the hero and the problem; every item repeats a number already sourced on the page
const ITEMS = [
  "376 anti-smog guns, 266 sprinklers, 91 sweepers",
  "500 m cells, filled in by a digital twin",
  "72 h forecast, GRAP stage 24–48 h ahead",
  "Road dust: 15% of winter PM2.5, 64% of NCAP funds",
  "Every fix checked against similar untreated cells",
  "Nothing dispatches without an officer",
];

export function Marquee() {
  const row = ITEMS.map((t) => (
    <span key={t} className="flex flex-none items-center gap-10 whitespace-nowrap">
      <span>{t}</span><i className="size-1.5 flex-none bg-teal" />
    </span>
  ));
  return (
    <div aria-hidden className="group relative overflow-hidden rounded-lg border border-ink/[.08] bg-paper/95 py-3.5 text-[15px] font-medium text-ink">
      <div className="flex w-max animate-[marquee_46s_linear_infinite] group-hover:[animation-play-state:paused]">
        <div className="flex gap-10 pr-10">{row}</div>
        <div className="flex gap-10 pr-10">{row}</div>
      </div>
    </div>
  );
}
