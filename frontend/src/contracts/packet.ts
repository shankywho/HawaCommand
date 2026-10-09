// MQTT telemetry packet schema v1 (dev, role, seq, ts, gps, pm, gas, env, flags, fw, batt): identical for real pod and simulator
import { z } from "zod";

export const DeviceRole = z.enum(["pod", "tag"]);

export const PacketV1 = z.object({
  v: z.literal(1),
  dev: z.string().min(1),
  role: DeviceRole,
  seq: z.number().int().nonnegative(),
  /** Unix epoch, seconds. */
  ts: z.number().int().positive(),
  gps: z.object({ lat: z.number(), lon: z.number(), fix: z.boolean(), hdop: z.number().optional() }),
  pm: z.object({ pm1: z.number(), pm25: z.number(), pm10: z.number() }).optional(),
  gas: z.object({ no2: z.number().optional(), co: z.number().optional(), voc: z.number().optional() }).optional(),
  env: z.object({ t: z.number(), rh: z.number(), p: z.number().optional() }).optional(),
  /** HawaTag only: pump state and flow. */
  pump: z.object({ on: z.boolean(), lpm: z.number().nonnegative() }).optional(),
  flags: z.object({ spike: z.boolean().default(false), tamper: z.boolean().default(false), sim: z.boolean().default(false) }),
  fw: z.string(),
  batt: z.number().min(0).max(100),
  rssi: z.number().optional(),
});
export type PacketV1 = z.infer<typeof PacketV1>;

export const TOPIC = {
  telemetry: (dev: string) => `hawa/v1/${dev}/telemetry`,
} as const;
