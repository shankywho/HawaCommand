"use client";
// animated number (replaces the prototype's <hc-count>); respects reduced motion
import { useEffect, useRef, useState } from "react";

export function CountUp({ to, from = 0, dur = 900, prefix = "", suffix = "", decimals = 0 }: {
  to: number; from?: number; dur?: number; prefix?: string; suffix?: string; decimals?: number;
}) {
  const [v, setV] = useState(from);
  const cur = useRef(from);
  const ref = useRef<HTMLSpanElement>(null);
  const seen = useRef(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    let raf = 0;
    const run = () => {
      const start = cur.current, t0 = performance.now();
      if (matchMedia("(prefers-reduced-motion: reduce)").matches) return setV((cur.current = to));
      const step = (n: number) => {
        const k = Math.min(1, (n - t0) / dur), e = 1 - Math.pow(1 - k, 3);
        cur.current = start + (to - start) * e;
        setV(cur.current);
        if (k < 1) raf = requestAnimationFrame(step);
      };
      raf = requestAnimationFrame(step);
    };
    if (seen.current) run();
    const io = new IntersectionObserver(([e]) => {
      if (e?.isIntersecting && !seen.current) { seen.current = true; run(); io.disconnect(); }
    });
    io.observe(el);
    return () => { io.disconnect(); cancelAnimationFrame(raf); };
  }, [to, dur]);

  return (
    <span ref={ref} className="tabular-nums">
      {prefix}
      {v.toLocaleString("en-IN", { minimumFractionDigits: decimals, maximumFractionDigits: decimals })}
      {suffix}
    </span>
  );
}
