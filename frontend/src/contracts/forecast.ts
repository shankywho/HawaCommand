// Forecast series P10/P50/P90 + GRAP stage
import { z } from "zod";
import { Confidence, IsoDateTime } from "./common";

export const GrapStage = z.enum(["I", "II", "III", "IV"]);

export const ForecastPoint = z.object({ h: z.number().int(), p10: z.number(), p50: z.number(), p90: z.number() });
export type ForecastPoint = z.infer<typeof ForecastPoint>;

export const WardExposure = z.object({
  ward: z.string(),
  peopleHours: z.number(),
  peakPm25: z.number(),
  confidence: Confidence,
});
export type WardExposure = z.infer<typeof WardExposure>;

export const Forecast = z.object({
  issuedAt: IsoDateTime,
  ward: z.string(),
  grap: z.object({ stage: GrapStage, likelyAt: IsoDateTime, probability: Confidence, headline: z.string(), actions: z.array(z.string()).default([]) }),
  series: z.array(ForecastPoint),
  wards: z.array(WardExposure),
});
export type Forecast = z.infer<typeof Forecast>;
