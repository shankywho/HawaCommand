"use client";
import { useMemo } from "react";
import { useForecast } from "@/hooks/useConsoleData";
import { useHotspots } from "@/hooks/useHotspots";

/** What the landing page may claim about "right now": the same API the console reads, never invented numbers. */
export function useLandingAir() {
  const hs = useHotspots(0).data;
  const grap = useForecast().data?.grap;
  return useMemo(() => {
    const items = hs?.items ?? [];
    const top = items.length ? items.reduce((a, b) => (b.pm25 > a.pm25 ? b : a)) : undefined;
    return { top, count: items.length, grap, simulated: hs?.simulated ?? true, asOf: hs?.asOf };
  }, [hs, grap]);
}
