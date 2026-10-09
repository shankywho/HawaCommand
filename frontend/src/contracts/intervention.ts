// Intervention + Impact (effectPct, ciLow, ciHigh, durationMin, method, donorCells)
import { z } from "zod";
import { Cause, IsoDateTime, listOf } from "./common";

export const Verdict = z.enum(["Verified", "Inconclusive", "No effect"]);
export type Verdict = z.infer<typeof Verdict>;

export const Impact = z.object({
  pollutant: z.enum(["pm25", "pm10"]),
  effectPct: z.number(),
  ciLow: z.number(),
  ciHigh: z.number(),
  durationMin: z.number().nonnegative(),
  method: z.literal("synthetic_control"),
  donorCells: z.array(z.object({ cellId: z.string(), weight: z.number() })),
  verdict: Verdict,
  /** Observed vs counterfactual series for the chart. */
  series: z
    .array(z.object({ t: IsoDateTime, observed: z.number(), control: z.number(), lo: z.number(), hi: z.number() }))
    .optional(),
});
export type Impact = z.infer<typeof Impact>;

export const Intervention = z.object({
  id: z.string(),
  planId: z.string().optional(),
  asset: z.string(),
  action: z.string(),
  cellId: z.string(),
  place: z.string(),
  cause: Cause,
  startedAt: IsoDateTime,
  endedAt: IsoDateTime.optional(),
  simulated: z.boolean(),
  impact: Impact.optional(),
});
export type Intervention = z.infer<typeof Intervention>;

export const InterventionList = listOf(Intervention).extend({
  summary: z.object({ verifiedPct: z.number(), targetPct: z.number(), noEffect: z.number(), wrongTool: z.number() }),
});
export type InterventionList = z.infer<typeof InterventionList>;

export const EffectLibraryRow = z.object({
  action: z.string(),
  cause: Cause,
  weather: z.string(),
  effectPct: z.number(),
  ci: z.tuple([z.number(), z.number()]),
  durationMin: z.number().nullable(),
  n: z.number().int(),
});
export type EffectLibraryRow = z.infer<typeof EffectLibraryRow>;
