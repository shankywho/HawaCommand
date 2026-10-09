"use client";
// observed vs counterfactual with band and spray window
import type { Impact } from "@hawa/contracts";
import { useElementWidth } from "@/components/charts/useElementWidth";
import { clock } from "@/lib/time";
import { fmtPct, pollutantLabel } from "@/lib/format";

export function SyntheticControlChart({ impact, asset, height = 200, sprayFrom = 12, sprayTo = 15 }: {
  impact: Impact; asset: string; height?: number; sprayFrom?: number; sprayTo?: number;
}) {
  const [ref, W] = useElementWidth<HTMLDivElement>();
  const s = impact.series ?? [];
  const H = height, pad = { l: 38, r: 12, t: 18, b: 24 };
  const iw = Math.max(1, W - pad.l - pad.r), ih = H - pad.t - pad.b, N = s.length;
  const y0 = 250, y1 = 500;
  const X = (i: number) => pad.l + (i / Math.max(1, N - 1)) * iw;
  const Y = (v: number) => pad.t + (1 - (v - y0) / (y1 - y0)) * ih;
  const mono = { fontFamily: "var(--font-geist-mono)", fontSize: 10.5, fill: "#5F6B70" };
  const effectEnd = Math.min(N - 1, sprayFrom + 2 + Math.round(impact.durationMin / 5));
  const mid = s[Math.round((sprayFrom + effectEnd) / 2)];
  const yb = mid ? Y(mid.control * (1 + impact.effectPct / 100)) + 26 : 0;

  return (
    <div ref={ref}>
      {W > 0 && N > 1 && (
        <svg width={W} height={H} viewBox={`0 0 ${W} ${H}`} className="block overflow-visible">
          {[250, 300, 350, 400, 450, 500].map((v) => (
            <g key={v}>
              <line x1={pad.l} x2={W - pad.r} y1={Y(v)} y2={Y(v)} stroke="#ECE9E2" />
              <text x={pad.l - 6} y={Y(v) + 3.5} textAnchor="end" style={mono}>{v}</text>
            </g>
          ))}
          <rect x={X(sprayFrom)} y={pad.t} width={X(sprayTo) - X(sprayFrom)} height={ih} fill="#0F766E" opacity={0.12} />
          <text x={X(sprayFrom) + 4} y={pad.t + 11} style={{ font: "500 10.5px var(--font-geist)", fill: "#0F766E" }}>Spray · {asset}</text>
          <path d={`M${s.map((p, i) => `${X(i)},${Y(p.hi)}`).join("L")}L${[...s].reverse().map((p, j) => `${X(N - 1 - j)},${Y(p.lo)}`).join("L")}Z`} fill="rgba(11,18,21,.07)" />
          <path d={`M${s.map((p, i) => `${X(i)},${Y(p.control)}`).join("L")}`} fill="none" stroke="#5F6B70" strokeWidth={1.25} strokeDasharray="4 3" />
          <path d={`M${s.map((p, i) => `${X(i)},${Y(p.observed)}`).join("L")}`} fill="none" stroke="#0B1215" strokeWidth={1.75} strokeLinejoin="round" />
          {mid && (
            <>
              <path d={`M${X(sprayFrom + 2)},${yb - 5}V${yb}H${X(effectEnd)}V${yb - 5}`} fill="none" stroke="#0B1215" />
              <text x={(X(sprayFrom + 2) + X(effectEnd)) / 2} y={yb + 13} textAnchor="middle" style={{ ...mono, fill: "#0B1215", fontWeight: 500, fontSize: 11 }}>
                {pollutantLabel(impact.pollutant)} {fmtPct(impact.effectPct)} · {impact.durationMin} min
              </text>
            </>
          )}
          {[0, 12, 24, 36, 48].filter((i) => i < N).map((i, k, a) => (
            <text key={i} x={X(i)} y={H - 6} textAnchor={k === 0 ? "start" : k === a.length - 1 ? "end" : "middle"} style={mono}>{clock(s[i]!.t)}</text>
          ))}
        </svg>
      )}
    </div>
  );
}

export function ChartKey() {
  return (
    <div className="mb-2 flex flex-wrap gap-4 text-[13px] text-muted">
      <span className="flex items-center gap-1.5"><i className="h-0.5 w-3.5 bg-ink" />Observed</span>
      <span className="flex items-center gap-1.5"><i className="w-3.5 border-t-2 border-dashed border-muted" />Synthetic control</span>
      <span className="flex items-center gap-1.5"><i className="h-2 w-3.5 bg-ink/10" />95% band</span>
    </div>
  );
}
