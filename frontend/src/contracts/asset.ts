// Fleet asset + HawaTag live state
import { z } from "zod";
import { AssetKind, IsoDateTime, LonLat, listOf } from "./common";

export const AssetStatus = z.enum(["Spraying", "En route", "Done", "On site", "Refilling", "Offline", "Idle"]);
export type AssetStatus = z.infer<typeof AssetStatus>;

export const HawaTagState = z.object({
  tagId: z.string(),
  fw: z.string(),
  pumpOn: z.boolean(),
  flowLpm: z.number().nonnegative(),
  litresThisRun: z.number().nonnegative(),
  tankLitres: z.number().positive(),
  pm10Before: z.number().optional(),
  pm10Now: z.number().optional(),
  sprayWindows: z.array(z.object({ start: z.string(), end: z.string() })),
  tamperIntact: z.boolean(),
  signalDbm: z.number(),
  trust: z.number().min(0).max(1),
  lastSeq: z.number().int(),
});

export const Asset = z.object({
  id: z.string(),
  kind: AssetKind,
  label: z.string(),
  depot: z.string().optional(),
  task: z.string(),
  status: AssetStatus,
  tagSummary: z.string(),
  lastPingAt: IsoDateTime,
  at: LonLat.optional(),
  simulated: z.boolean(),
  tag: HawaTagState.optional(),
});
export type Asset = z.infer<typeof Asset>;

export const AssetList = listOf(Asset);
export type AssetList = z.infer<typeof AssetList>;
