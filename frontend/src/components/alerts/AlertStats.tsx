"use client";
// headline numbers for the alert log, and one bar per alert showing how early it went out
import type { Alert } from "@hawa/contracts";
import { CountUp } from "@/components/ui/CountUp";

const reached = (a: Alert) => Number(/([\d,]+)\s+delivered/.exec(a.delivered)?.[1]?.replace(/,/g, "") ?? 0);

export function AlertStats({ items }: { items: Alert[] }) {
  if (!items.length) return null;
  const leads = items.flatMap((a) => (a.leadTimeH === null ? [] : [a.leadTimeH]));
  const sorted = [...leads].sort((a, b) => a - b);
  const median = sorted.length ? sorted[Math.floor(sorted.length / 2)]! : 0;
  const longest = Math.max(1, ...leads);
  const total = items.reduce((s, a) => s + reached(a), 0);
  const tiles: [string, React.ReactNode, string][] = [
    ["Alerts sent", <CountUp key="a" to={items.length} dur={700} />, "this window"],
    ["People reached", <CountUp key="r" to={total} dur={1100} />, "delivered, all channels"],
    ["Median lead time", <><CountUp key="m" to={median} dur={900} decimals={1} /><span className="text-[22px] font-medium text-muted"> h</span></>, "before the forecast spike"],
    ["Channels", <>{new Set(items.map((a) => a.channel)).size}</>, [...new Set(items.map((a) => a.channel))].join(" · ")],
  ];
  return (
    <>
      <div className="grid grid-cols-2 gap-px overflow-hidden rounded-[10px] border border-line bg-line min-[1100px]:grid-cols-4">
        {tiles.map(([k, v, sub], i) => (
          <div key={k} style={{ animationDelay: `${i * 70}ms` }} className="flex animate-[pageIn_.5s_cubic-bezier(.2,.7,.2,1)_both] flex-col gap-1 bg-white px-5 py-4">
            <span className="text-[13px] text-muted">{k}</span>
            <span className="text-[clamp(28px,2.4vw,40px)] font-semibold leading-none tracking-[-.03em]">{v}</span>
            <span className="text-[12.5px] text-muted-2">{sub}</span>
          </div>
        ))}
      </div>
      {leads.length > 0 && (
        <div className="card flex flex-col gap-2.5 px-5 py-4">
          <span className="text-[13px] font-medium text-muted">How early each alert went out</span>
          {items.filter((a) => a.leadTimeH !== null).map((a, i) => (
            <div key={a.id} className="grid grid-cols-[minmax(120px,220px)_minmax(0,1fr)_56px] items-center gap-3 text-sm">
              <span className="truncate">{a.target}</span>
              <span className="h-2.5 overflow-hidden rounded-sm bg-line-soft"><i className="block h-full origin-left animate-[barIn_.9s_cubic-bezier(.2,.7,.2,1)_both] rounded-sm bg-teal" style={{ width: `${((a.leadTimeH ?? 0) / longest) * 100}%`, animationDelay: `${200 + i * 90}ms` }} /></span>
              <span className="text-right font-mono text-[13px]">{a.leadTimeH} h</span>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
