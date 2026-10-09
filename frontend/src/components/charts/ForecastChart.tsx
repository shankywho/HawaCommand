"use client";
// P10–P90 band + P50 line over CPCB band shading; optional "now" marker for the scrubber hour
import { dayHour, hoursAtClock } from "@/lib/time";
import type { ForecastPoint } from "@hawa/contracts";
import { BAND_COLORS } from "@hawa/contracts";
import { useElementWidth } from "./useElementWidth";

export function ForecastChart({ series, hour, height = 120, compact = true }: { series: ForecastPoint[]; hour?: number; height?: number; compact?: boolean }) {
  const [ref, W] = useElementWidth<HTMLDivElement>();
  const H = height;
  const pad = compact ? { l: 30, r: 6, t: 8, b: 18 } : { l: 38, r: 12, t: 14, b: 24 };
  const iw = Math.max(1, W - pad.l - pad.r), ih = H - pad.t - pad.b;
  const maxH = series.at(-1)?.h ?? 72;
  const y0 = 100, y1 = Math.max(500, Math.ceil(Math.max(...series.map((p) => p.p90)) / 100) * 100);
  const X = (h: number) => pad.l + (h / maxH) * iw;
  const Y = (v: number) => pad.t + (1 - (v - y0) / (y1 - y0)) * ih;
  const mono = { fontFamily: "var(--font-geist-mono)", fontSize: 10.5, fill: "#5F6B70" };
  const at = hour === undefined ? undefined : series.find((p) => p.h === Math.max(0, Math.round(hour)));

  return (
    <div ref={ref} className="w-full">
      {W > 0 && (
        <svg width={W} height={H} viewBox={`0 0 ${W} ${H}`} className="block overflow-visible">
          {([[100, 120, 3], [121, 250, 4], [251, y1, 5]] as const).map(([a, b, c]) => (
            <rect key={c} x={pad.l} width={iw} y={Y(b)} height={Y(a) - Y(b)} fill={BAND_COLORS[c]} opacity={0.07} />
          ))}
          {Array.from({ length: (y1 - y0) / 100 + 1 }, (_, i) => y0 + i * 100).map((v) => (
            <g key={v}>
              <line x1={pad.l} x2={W - pad.r} y1={Y(v)} y2={Y(v)} stroke="#ECE9E2" />
              <text x={pad.l - 5} y={Y(v) + 3.5} textAnchor="end" style={mono}>{v}</text>
            </g>
          ))}
          <path
            d={`M${series.map((p) => `${X(p.h)},${Y(p.p90)}`).join("L")}L${[...series].reverse().map((p) => `${X(p.h)},${Y(p.p10)}`).join("L")}Z`}
            fill="rgba(11,18,21,.07)"
          />
          <path d={`M${series.map((p) => `${X(p.h)},${Y(p.p50)}`).join("L")}`} fill="none" stroke="#0B1215" strokeWidth={1.6} strokeLinejoin="round" />
          {at && (
            <>
              <line x1={X(at.h)} x2={X(at.h)} y1={pad.t} y2={pad.t + ih} stroke="#0F766E" strokeWidth={1.25} />
              <circle cx={X(at.h)} cy={Y(at.p50)} r={3.5} fill="#0F766E" stroke="#FAF9F6" strokeWidth={1.5} />
            </>
          )}
          {([[0, "Now"], ...hoursAtClock(8, 1, 72).map((h): [number, string] => [h, dayHour(h)])] as [number, string][]).map(([h, l], i) => (
            <text key={l} x={X(h)} y={H - 5} textAnchor={i === 0 ? "start" : "middle"} style={mono}>{l}</text>
          ))}
        </svg>
      )}
    </div>
  );
}
