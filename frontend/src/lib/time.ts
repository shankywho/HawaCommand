// demo clock + hour-offset helpers. "Now" is fixed for the demo; switch to real time when the twin is live.
export const IST = "Asia/Kolkata";

/** Tue 10 Nov 2026, 14:00 IST: the moment the demo narrative is set in. */
export const DEMO_NOW = new Date("2026-11-10T14:00:00+05:30");

export const now = () => (process.env.NEXT_PUBLIC_API_URL ? new Date() : DEMO_NOW);

export const addHours = (d: Date, h: number) => new Date(d.getTime() + h * 3_600_000);
export const isoAt = (h: number, base = DEMO_NOW) => addHours(base, h).toISOString();

const dayFmt = new Intl.DateTimeFormat("en-GB", { weekday: "short", timeZone: IST });
const timeFmt = new Intl.DateTimeFormat("en-GB", { hour: "2-digit", minute: "2-digit", hour12: false, timeZone: IST });

/** "Thu 08:00" */
export const dayTime = (d: Date | string) => {
  const x = typeof d === "string" ? new Date(d) : d;
  return `${dayFmt.format(x)} ${timeFmt.format(x)}`;
};
export const clock = (d: Date | string) => timeFmt.format(typeof d === "string" ? new Date(d) : d);

/** Relative hour from the scrubber to a label: 0 -> "Now · Tue 14:00", 42 -> "Thu 08:00 · +42 h". */
export const hourLabel = (hour: number, base = now()) => {
  const t = dayTime(addHours(base, hour));
  if (hour === 0) return `Now · ${t}`;
  return `${t} · ${hour > 0 ? "+" : "−"}${Math.abs(hour)} h`;
};

/** Diurnal + episode multiplier the demo twin uses (peak Thu 08:00 = +42 h). */
export const episode = (h: number) =>
  1 +
  0.14 * (Math.cos((2 * Math.PI * (h - 18)) / 24) - Math.cos((2 * Math.PI * -18) / 24)) +
  0.2 * Math.exp(-Math.pow((h - 42) / 12, 2));

/** Fallback peak while forecasts load; the real peak comes from usePeakHour(). */
export const PEAK_HOUR = 42;

const hourFmt = new Intl.DateTimeFormat("en-GB", { hour: "2-digit", hour12: false, timeZone: IST });

/** Hour offsets (from now) within [from, to] at which the IST wall clock reads `hh`:xx. */
export const hoursAtClock = (hh: number, from = 0, to = 72, base = now()) => {
  const out: number[] = [];
  for (let h = from; h <= to; h++) if (Number(hourFmt.format(addHours(base, h))) % 24 === hh) out.push(h);
  return out;
};

/** "Sun 08" */
export const dayHour = (h: number, base = now()) => dayTime(addHours(base, h)).slice(0, 6);

/** "Sat 04:42 – 08:42" from a plan window. */
export const windowLabel = (w: { start: string; end: string }) => `${dayTime(w.start)} – ${clock(w.end)}`;
