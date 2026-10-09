"use client";
// MapLibre (OpenFreeMap positron) map with the PM2.5 twin, hotspots, fleet and school layers.
// Renders the design's <hawa-gl> element; the typed props here are the contract the page code relies on.
import { useEffect, useRef } from "react";
import type { MapLayer, MapStation } from "./layers";

export type HawaMapProps = {
  layers: MapLayer[];
  mode?: "live" | "plan" | "usual" | "donor";
  /** Hours relative to now (−24 … +72). */
  hour?: number;
  /** 0 = usual routes, 1 = plan (landing What-If slider). */
  mix?: number;
  thresholdUgm3?: number;
  assets?: string[];
  selected?: string | null;
  center?: [number, number];
  zoom?: number;
  labels?: "full" | "major" | "sel" | "none";
  maxLabels?: number;
  extrude?: { pitch: number; bearing: number; hscale: number };
  interactive?: boolean;
  attribution?: boolean;
  attributionBottom?: number;
  /** Live hotspots drawn as the heat field and station markers. Omit to use the built-in demo field. */
  stations?: MapStation[];
  /** Real asset positions; replaces the demo truck routes. */
  fleet?: { id: string; lon: number; lat: number; icon?: string }[];
  /** Donor-cell weights (0..1) for mode="donor". */
  donors?: number[];
  onHotspotClick?: (cellId: string) => void;
  className?: string;
};

export function HawaMap({
  layers, mode = "live", hour = 0, mix, thresholdUgm3, assets, selected, center = [77.17, 28.645], zoom = 10.35,
  labels = "major", maxLabels, extrude, interactive = true, attribution = true, attributionBottom, stations, fleet, donors, onHotspotClick, className,
}: HawaMapProps) {
  const ref = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el || !onHotspotClick) return;
    const h = (e: Event) => onHotspotClick((e as CustomEvent<{ id: string }>).detail.id);
    el.addEventListener("hc-hotspot", h);
    return () => el.removeEventListener("hc-hotspot", h);
  }, [onHotspotClick]);

  useEffect(() => {
    const el = ref.current as (HTMLElement & { data?: unknown; fleet?: unknown; donors?: unknown }) | null;
    if (!el) return;
    let live = true;
    customElements.whenDefined("hawa-gl").then(() => {
      if (!live) return;
      el.data = stations ?? null;
      el.fleet = fleet ?? null;
      el.donors = donors ?? null;
    });
    return () => {
      live = false;
    };
  }, [stations, fleet, donors]);

  return (
    <hawa-gl
      ref={ref}
      theme="light"
      mode={mode}
      hour={String(hour)}
      mix={mix === undefined ? undefined : mix.toFixed(3)}
      threshold={thresholdUgm3 === undefined ? undefined : String(thresholdUgm3)}
      layers={layers.join(",")}
      assets={assets?.join(",")}
      selected={selected ?? ""}
      center={center.join(",")}
      zoom={String(zoom)}
      labels={labels}
      maxlabels={maxLabels === undefined ? undefined : String(maxLabels)}
      {...(extrude ? { extrude: "", pitch: String(extrude.pitch), bearing: String(extrude.bearing), hscale: String(extrude.hscale) } : {})}
      interactive={interactive ? undefined : "false"}
      attrib={attribution ? undefined : "none"}
      attrib-bottom={attributionBottom === undefined ? undefined : String(attributionBottom)}
      className={className}
      style={{ position: "absolute", inset: 0 }}
    />
  );
}

/** Small floating label on top of a map. */
export function MapBadge({ children, accent, className = "left-3 top-3" }: { children: React.ReactNode; accent?: boolean; className?: string }) {
  return (
    <span className={`absolute flex h-[30px] items-center whitespace-nowrap rounded-lg border bg-white px-[11px] text-[13.5px] font-medium ${accent ? "border-teal" : "border-line"} ${className}`}>
      {children}
    </span>
  );
}
