"use client";
import { useMemo } from "react";
import { PEAK_HOUR } from "@/lib/time";
import { useWardHotspots } from "./useHotspots";

/** Forecast hour (1-72) at which the mean hotspot PM2.5 P50 is highest. */
export function usePeakHour(): number {
  const items = useWardHotspots(0).data?.items;
  return useMemo(() => {
    if (!items?.length) return PEAK_HOUR;
    let best = 0;
    let bestV = -1;
    for (let h = 1; h <= 72; h++) {
      const v = items.flatMap((i) => i.forecast?.find((f) => f.h === h)?.p50 ?? []);
      const mean = v.length ? v.reduce((a, b) => a + b, 0) / v.length : -1;
      if (mean > bestV) {
        bestV = mean;
        best = h;
      }
    }
    return best || PEAK_HOUR;
  }, [items]);
}
