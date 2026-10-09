// shared primitives: ids, coordinates, confidence, causes
import { z } from "zod";

export const LonLat = z.tuple([z.number().min(-180).max(180), z.number().min(-90).max(90)]);
export type LonLat = z.infer<typeof LonLat>;

/** 0..1 model confidence. UI turns it into High / Medium / Low words. */
export const Confidence = z.number().min(0).max(1);

export const CAUSES = ["Dust", "Traffic", "Burning", "Regional smoke"] as const;
export const Cause = z.enum(CAUSES);
export type Cause = z.infer<typeof Cause>;

export const IsoDateTime = z.string().datetime({ offset: true });

export const ASSET_KINDS = ["sprinkler", "smog_gun", "sweeper", "inspection", "communicator"] as const;
export const AssetKind = z.enum(ASSET_KINDS);
export type AssetKind = z.infer<typeof AssetKind>;

/** Every list endpoint returns this envelope. */
export const listOf = <T extends z.ZodTypeAny>(item: T) =>
  z.object({ asOf: IsoDateTime, simulated: z.boolean().default(false), items: z.array(item) });
