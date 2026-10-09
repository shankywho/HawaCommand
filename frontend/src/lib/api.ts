// typed fetch client for /v1/* using @hawa/contracts. Every response is validated with zod, so a
// backend that drifts from the contract fails loudly here instead of rendering wrong numbers.
import {
  AlertList, AssetList, DraftPlanRequest, DriverRoute, EffectLibraryRow, Forecast, HotspotList,
  InterventionList, Plan, PlanComparison, listOf, type HotspotQuery,
} from "@hawa/contracts";
import { z } from "zod";
import { getIdToken } from "./auth";

export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "";
export const USING_MOCKS = !API_URL;

export class ApiError extends Error {
  constructor(public status: number, message: string, public body?: unknown) {
    super(message);
  }
}

async function request<S extends z.ZodTypeAny>(schema: S, method: "GET" | "POST", path: string, body?: unknown): Promise<z.infer<S>> {
  let data: unknown;
  if (USING_MOCKS) {
    const { mockFetch } = await import("@/mocks/handlers");
    data = await mockFetch(method, path, body);
  } else {
    const token = await getIdToken();
    const res = await fetch(`${API_URL}${path}`, {
      method,
      headers: {
        "content-type": "application/json",
        ...(token ? { authorization: `Bearer ${token}` } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    data = await res.json().catch(() => undefined);
    if (!res.ok) throw new ApiError(res.status, `${method} ${path} failed with ${res.status}`, data);
  }
  const parsed = schema.safeParse(data);
  if (!parsed.success) {
    console.error(`[api] ${method} ${path} does not match contract`, parsed.error.flatten());
    throw new ApiError(500, `${method} ${path}: response does not match @hawa/contracts`, parsed.error);
  }
  return parsed.data;
}

const qs = (o: Record<string, string | number | undefined>) => {
  const p = new URLSearchParams();
  for (const [k, v] of Object.entries(o)) if (v !== undefined && v !== "") p.set(k, String(v));
  const s = p.toString();
  return s ? `?${s}` : "";
};

export const api = {
  hotspots: (q: Partial<HotspotQuery> = {}) => request(HotspotList, "GET", `/v1/hotspots${qs(q)}`),
  forecast: (ward?: string) => request(Forecast, "GET", `/v1/forecast${qs({ ward })}`),
  plans: {
    list: () => request(listOf(Plan), "GET", "/v1/plans"),
    get: (id: string) => request(Plan, "GET", `/v1/plans/${id}`),
    draft: (req: DraftPlanRequest) => request(Plan, "POST", "/v1/plans/draft", req),
    compare: (id: string) => request(PlanComparison, "GET", `/v1/plans/${id}/compare`),
    applySuggestion: (id: string, commentId: string) =>
      request(Plan, "POST", `/v1/plans/${id}/suggestions/${commentId}/apply`),
    approve: (id: string, note?: string) => request(Plan, "POST", `/v1/plans/${id}/approve`, { note }),
    requestChanges: (id: string, note: string) => request(Plan, "POST", `/v1/plans/${id}/request-changes`, { note }),
  },
  devices: () => request(AssetList, "GET", "/v1/devices"),
  impact: {
    list: () => request(InterventionList, "GET", "/v1/impact"),
    library: () => request(listOf(EffectLibraryRow), "GET", "/v1/impact/library"),
  },
  alerts: () => request(AlertList, "GET", "/v1/alerts"),
  driverRoute: (asset: string) => request(DriverRoute, "GET", `/v1/driver/route${qs({ asset })}`),
};
