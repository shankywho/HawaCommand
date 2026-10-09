// Hotspot: cellId, place, ward, pm25, band, cause, causeConf, suspectPin, exposurePh, schools[]
import { z } from "zod";
import { Band } from "./aqi";
import { Cause, Confidence, LonLat, listOf } from "./common";
import { ForecastPoint } from "./forecast";

export const NearbySchool = z.object({
  id: z.string(),
  name: z.string(),
  distanceKm: z.number().nonnegative(),
  assemblyAt: z.string().optional(),
});
export type NearbySchool = z.infer<typeof NearbySchool>;

export const SuspectPin = z.object({
  label: z.string(),
  at: LonLat.optional(),
  bearing: z.string().optional(),
  distanceKm: z.number().optional(),
  travelMin: z.number().optional(),
});

export const Hotspot = z.object({
  cellId: z.string(),
  place: z.string(),
  placeFull: z.string().optional(),
  ward: z.string(),
  at: LonLat,
  /** PM2.5 in µg/m³ (concentration, not AQI). */
  pm25: z.number().nonnegative(),
  band: Band,
  cause: Cause,
  causeConf: Confidence,
  /** Confidence in the concentration estimate itself. */
  conf: Confidence,
  suspectPin: SuspectPin,
  /** People-hours of exposure over the next 4 h. */
  exposurePh: z.number().nonnegative(),
  rank: z.number().int().positive(),
  schools: z.array(NearbySchool),
  /** Asset ids currently assigned or routed near this cell. */
  assets: z.array(z.string()),
  /** 72-hour PM2.5 forecast for this cell (P10/P50/P90), hour 0 = now. */
  forecast: z.array(ForecastPoint).optional(),
});
export type Hotspot = z.infer<typeof Hotspot>;

export const HotspotList = listOf(Hotspot).extend({
  ward: z.string().optional(),
  /** Hours relative to now: negative = replay, positive = forecast. */
  hour: z.number().int().default(0),
  thresholdUgm3: z.number().default(250),
});
export type HotspotList = z.infer<typeof HotspotList>;

export const HotspotQuery = z.object({
  ward: z.string().optional(),
  hour: z.coerce.number().int().min(-24).max(72).default(0),
  threshold: z.coerce.number().default(250),
});
export type HotspotQuery = z.infer<typeof HotspotQuery>;
