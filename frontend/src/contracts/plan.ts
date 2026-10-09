// Plan, PlanTask (+/- diff vs usual route), AuditorComment, PlanStatus
import { z } from "zod";
import { AssetKind, Cause, Confidence, IsoDateTime } from "./common";

export const PlanStatus = z.enum(["drafting", "draft", "changes_requested", "approved", "dispatching", "done"]);
export type PlanStatus = z.infer<typeof PlanStatus>;

export const PlanTask = z.object({
  id: z.string(),
  /** add = new vs usual route, del = removed from usual route. */
  op: z.enum(["add", "del"]),
  time: z.string(),
  place: z.string(),
  action: z.string().optional(),
  cause: Cause.optional(),
  causeConf: Confidence.optional(),
  reason: z.string(),
  /** Set when an agent comment targets this task, or the task came from a suggestion. */
  flag: z.enum(["auditor", "suggested"]).optional(),
});
export type PlanTask = z.infer<typeof PlanTask>;

export const PlanAssetGroup = z.object({
  asset: z.string(),
  kind: AssetKind,
  label: z.string(),
  tasks: z.array(PlanTask),
});
export type PlanAssetGroup = z.infer<typeof PlanAssetGroup>;

export const AuditorComment = z.object({
  id: z.string(),
  taskId: z.string(),
  status: z.enum(["open", "applied", "dismissed"]),
  objection: z.string(),
  confidence: Confidence,
  suggestion: z.object({ remove: z.string(), add: z.string() }),
});
export type AuditorComment = z.infer<typeof AuditorComment>;

export const PlanCheck = z.object({ id: z.string(), label: z.string(), detail: z.string(), ok: z.boolean() });
export type PlanCheck = z.infer<typeof PlanCheck>;

export const Plan = z.object({
  id: z.string(),
  ward: z.string(),
  window: z.object({ start: IsoDateTime, end: IsoDateTime, label: z.string() }),
  status: PlanStatus,
  draftedAt: IsoDateTime,
  draftedBy: z.string(),
  approvedAt: IsoDateTime.optional(),
  headline: z.object({
    protectedPct: z.number(),
    peopleHoursSaved: z.number(),
    likelyRange: z.tuple([z.number(), z.number()]),
    peopleHoursUsual: z.number(),
    peopleHoursPlan: z.number(),
    assetsUsed: z.number().int(),
    assetsTotal: z.number().int(),
    extraKm: z.number(),
    confidence: Confidence,
  }),
  summary: z.string(),
  reasoning: z.string(),
  groups: z.array(PlanAssetGroup),
  comments: z.array(AuditorComment),
  checks: z.array(PlanCheck),
  /** Step Functions execution ARN once approved. */
  executionArn: z.string().optional(),
});
export type Plan = z.infer<typeof Plan>;

export const PlanSummary = Plan.pick({ id: true, ward: true, window: true, status: true, draftedAt: true });
export type PlanSummary = z.infer<typeof PlanSummary>;

export const DraftPlanRequest = z.object({ ward: z.string(), windowStart: IsoDateTime.optional() });
export type DraftPlanRequest = z.infer<typeof DraftPlanRequest>;

export const ApprovePlanRequest = z.object({ note: z.string().optional() });
export const RequestChangesRequest = z.object({ note: z.string().min(1) });

/** What-If: usual routes vs plan, one row per asset. */
export const RouteComparison = z.object({
  asset: z.string(),
  usual: z.string(),
  plan: z.string(),
  kmUsual: z.number().nullable(),
  kmPlan: z.number().nullable(),
  reachUsual: z.string(),
  reachPlan: z.string(),
  exposureDelta: z.number(),
});
export type RouteComparison = z.infer<typeof RouteComparison>;

export const PlanComparison = z.object({
  planId: z.string(),
  deltaPct: z.number(),
  rows: z.array(RouteComparison),
});
export type PlanComparison = z.infer<typeof PlanComparison>;

/** Driver PWA: one asset's stops for the shift. Hindi-first labels. */
export const DriverStop = z.object({
  n: z.number().int().positive(),
  placeHi: z.string(),
  placeEn: z.string(),
  actionEn: z.string(),
  from: z.string(),
  to: z.string(),
  status: z.enum(["todo", "active", "done"]),
});
export const DriverRoute = z.object({
  asset: z.string(),
  assetLabelHi: z.string(),
  planId: z.string(),
  dateLabel: z.string(),
  window: z.string(),
  stops: z.array(DriverStop),
  lastSpray: z
    .object({ placeHi: z.string(), litres: z.number(), pumpMin: z.number(), pumpOn: z.boolean() })
    .optional(),
});
export type DriverRoute = z.infer<typeof DriverRoute>;
