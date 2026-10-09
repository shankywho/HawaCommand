"use client";
import { useMemo } from "react";
import { useWardHotspots } from "@/hooks/useHotspots";
import { atHour, toMapStations } from "./layers";

/** Hotspots at `hour` as map stations; undefined until loaded so the map keeps its demo field meanwhile. */
export function useMapStations(hour: number) {
  const raw = useWardHotspots(0).data?.items;
  return useMemo(() => (raw?.length ? toMapStations(atHour(raw, hour)) : undefined), [raw, hour]);
}
