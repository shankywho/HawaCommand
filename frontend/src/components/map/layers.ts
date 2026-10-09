// Map layer vocabulary. Today these names drive the vendored <hawa-gl> renderer; when the map moves to
// MapLibre + deck.gl layers fed from the API, each key maps to one React layer component.
import { Bus, Hexagon, Radio, School, Truck, type LucideIcon } from "lucide-react";
import { pm25Band, type Hotspot } from "@hawa/contracts";
import type { LayerKey } from "@/stores/console";

export type MapLayer =
  | "hex" // PM2.5 twin, 500 m cells (HotspotLayer)
  | "stations" // hotspots + CAAQMS stations (HotspotLayer)
  | "causes" // cause label on hotspot markers
  | "suspect" // upwind suspect pin
  | "buses" // bus-mounted HawaPod trails (PodTrailLayer)
  | "trucks" // fleet assets + routes (FleetLayer)
  | "schools"
  | "buildings" // 3D buildings (What-If)
  | "anchors"; // Yamuna / Ring Road labels

export const LAYER_TOGGLES: { key: LayerKey; icon: LucideIcon; label: string; layers: MapLayer[] }[] = [
  { key: "heat", icon: Hexagon, label: "Heat", layers: ["hex"] },
  { key: "hotspots", icon: Radio, label: "Stations", layers: ["stations", "causes"] },
  { key: "trails", icon: Bus, label: "Bus trails", layers: ["buses"] },
  { key: "trucks", icon: Truck, label: "Fleet", layers: ["trucks"] },
  { key: "schools", icon: School, label: "Schools", layers: ["schools"] },
];

export const layersFor = (on: Record<LayerKey, boolean>): MapLayer[] =>
  LAYER_TOGGLES.filter((t) => on[t.key]).flatMap((t) => t.layers);

/** A hotspot as the map component draws it (heat field source + station marker). */
export type MapStation = { id: string; name: string; lon: number; lat: number; pm: number; cause: string; side: "r"; st: 1 };

const MAP_CAUSES = new Set(["Dust", "Traffic", "Burning", "Regional smoke"]);

/** Hotspots as they will be at `hour` (forecast P50 of each cell); unchanged for now or the past. */
export const atHour = (items: Hotspot[], hour: number): Hotspot[] =>
  hour > 0
    ? items.map((h) => {
        const p50 = h.forecast?.find((f) => f.h === hour)?.p50;
        return p50 === undefined ? h : { ...h, pm25: p50, band: pm25Band(p50) };
      })
    : items;

/** Hotspots -> map stations. */
export const toMapStations = (items: Hotspot[]): MapStation[] =>
  items.map((h) => ({
    id: h.cellId,
    name: h.place,
    lon: h.at[0],
    lat: h.at[1],
    pm: h.pm25,
    cause: MAP_CAUSES.has(h.cause) ? h.cause : "Dust",
    side: "r",
    st: 1,
  }));

/** Centre of a set of stations as [lon, lat]; undefined when empty. */
export const centroid = (st: MapStation[] | undefined): [number, number] | undefined =>
  st?.length ? [st.reduce((a, s) => a + s.lon, 0) / st.length, st.reduce((a, s) => a + s.lat, 0) / st.length] : undefined;

/** Stations after a plan that cuts excess exposure (PM2.5 above the threshold) by `fraction`. */
export const applyPlan = (st: MapStation[] | undefined, fraction: number, threshold: number): MapStation[] | undefined =>
  st?.map((s) => (s.pm > threshold ? { ...s, pm: threshold + (s.pm - threshold) * (1 - fraction) } : s));

/** Share of exposure a plan removes versus the usual routes, 0..1. */
export const planReduction = (h?: { peopleHoursUsual: number; peopleHoursPlan: number }) =>
  h && h.peopleHoursUsual > 0 ? Math.min(1, Math.max(0, 1 - h.peopleHoursPlan / h.peopleHoursUsual)) : 0;
