// In-browser mock of the /v1 API. Same paths and payloads as docs/API.md, so swapping to the real
// backend is only NEXT_PUBLIC_API_URL. Plan mutations are kept in memory for the session.
import type { Plan } from "@hawa/contracts";
import { isoAt } from "@/lib/time";
import * as fx from "./fixtures";

let plan: Plan = fx.plan214();

const applySuggestion = (p: Plan, commentId: string): Plan => {
  const c = p.comments.find((x) => x.id === commentId);
  if (!c || c.status !== "open") return p;
  return {
    ...p,
    comments: p.comments.map((x) => (x.id === commentId ? { ...x, status: "applied" } : x)),
    groups: p.groups.map((g) => ({
      ...g,
      tasks: g.tasks.map((t) =>
        t.id === c.taskId ? { ...t, op: "del", flag: undefined, reason: "Removed after Auditor review: water does not help smoke." } : t,
      ),
    })),
    checks: p.checks.map((k) => (k.id === "tool" ? { ...k, ok: true, detail: "All tasks" } : k)),
  };
};

type Handler = (m: RegExpMatchArray, url: URL, body: unknown) => unknown;
const routes: [method: string, pattern: RegExp, handler: Handler][] = [
  ["GET", /^\/v1\/hotspots$/, (_m, url) => {
    const hour = Number(url.searchParams.get("hour") ?? 0);
    const ward = url.searchParams.get("ward") ?? undefined;
    return { asOf: isoAt(0), simulated: true, ward, hour, thresholdUgm3: Number(url.searchParams.get("threshold") ?? 250), items: fx.hotspotsAt(hour) };
  }],
  ["GET", /^\/v1\/forecast$/, () => fx.forecast()],
  ["GET", /^\/v1\/plans$/, () => ({ asOf: isoAt(0), simulated: true, items: [plan] })],
  ["POST", /^\/v1\/plans\/draft$/, () => ({ ...plan, status: "drafting" })],
  ["GET", /^\/v1\/plans\/([^/]+)$/, () => plan],
  ["GET", /^\/v1\/plans\/([^/]+)\/compare$/, () => fx.compare214()],
  ["POST", /^\/v1\/plans\/([^/]+)\/suggestions\/([^/]+)\/apply$/, (m) => (plan = applySuggestion(plan, m[2]!))],
  ["POST", /^\/v1\/plans\/([^/]+)\/approve$/, () => {
    plan = applySuggestion(plan, "aud-1");
    return (plan = { ...plan, status: "approved", approvedAt: isoAt(4.7), executionArn: "arn:aws:states:ap-south-1:000000000000:execution:dispatch:plan-214" });
  }],
  ["POST", /^\/v1\/plans\/([^/]+)\/request-changes$/, () => (plan = { ...plan, status: "changes_requested" })],
  ["GET", /^\/v1\/devices$/, () => ({ asOf: isoAt(0), simulated: true, items: fx.fleet() })],
  ["GET", /^\/v1\/impact$/, () => ({
    asOf: isoAt(0), simulated: true, items: fx.interventions(),
    summary: { verifiedPct: 89, targetPct: 90, noEffect: 7, wrongTool: 5 },
  })],
  ["GET", /^\/v1\/impact\/library$/, () => ({ asOf: isoAt(0), simulated: true, items: fx.effectLibrary() })],
  ["GET", /^\/v1\/alerts$/, () => ({
    asOf: isoAt(0), simulated: true, items: fx.alerts(),
    counts: { All: 146, School: 38, Citizens: 96, "Citizen Eyes": 12 },
  })],
  ["GET", /^\/v1\/driver\/route$/, (_m, url) => fx.driverRoute(url.searchParams.get("asset") ?? "T-12")],
];

export async function mockFetch(method: string, path: string, body?: unknown): Promise<unknown> {
  const url = new URL(path, "http://mock");
  await new Promise((r) => setTimeout(r, 120));
  for (const [m, re, h] of routes) {
    const match = url.pathname.match(re);
    if (m === method && match) return structuredClone(h(match, url, body));
  }
  throw new Error(`mock: no handler for ${method} ${url.pathname}`);
}
