// Alert: audience, target, channel, lang (hi/en), message, leadTimeH
import { z } from "zod";
import { IsoDateTime, listOf } from "./common";

export const Audience = z.enum(["School", "Citizens", "Citizen Eyes", "Workers", "Drivers"]);
export const Channel = z.enum(["WhatsApp", "SMS"]);
export const Lang = z.enum(["hi", "en", "hi+en"]);

export const Alert = z.object({
  id: z.string(),
  sentAt: IsoDateTime,
  audience: Audience,
  target: z.string(),
  channel: Channel,
  lang: Lang,
  message: z.string(),
  messageHi: z.string().optional(),
  delivered: z.string(),
  leadTimeH: z.number().nullable(),
  draftedBy: z.string().default("Communicator"),
});
export type Alert = z.infer<typeof Alert>;

export const AlertList = listOf(Alert).extend({ counts: z.record(z.string(), z.number()) });
export type AlertList = z.infer<typeof AlertList>;
