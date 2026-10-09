import {
  AlertList,
  AssetList,
  DraftPlanRequest,
  DriverRoute,
  EffectLibraryRow,
  Forecast,
  HotspotList,
  InterventionList,
  Plan,
  PlanComparison,
  listOf,
} from "../src/contracts";

const BACKEND_URL = process.env.API_URL || "http://127.0.0.1:8099";

async function checkEndpoint(name: string, url: string, schema: any, options: RequestInit = {}) {
  const fullUrl = `${BACKEND_URL}${url}`;
  const res = await fetch(fullUrl, {
    headers: { "content-type": "application/json", ...options.headers },
    ...options,
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`[FAIL] ${name} HTTP ${res.status}: ${text}`);
  }

  const json = await res.json();
  const parsed = schema.safeParse(json);
  if (!parsed.success) {
    console.error(`[FAIL] ${name} schema mismatch:`, JSON.stringify(parsed.error.flatten(), null, 2));
    throw new Error(`[FAIL] ${name} response failed zod validation`);
  }

  console.log(`[PASS] ${name} (${url}) -> Validated successfully!`);
  return parsed.data;
}

async function main() {
  console.log(`Connecting to backend at ${BACKEND_URL}...`);

  // 1. Hotspots
  await checkEndpoint("GET /v1/hotspots", "/v1/hotspots", HotspotList);
  await checkEndpoint("GET /v1/hotspots?hour=2&ward=West", "/v1/hotspots?hour=2&ward=West", HotspotList);

  // 2. Forecast
  await checkEndpoint("GET /v1/forecast", "/v1/forecast", Forecast);

  // 3. Plans List
  const plans = await checkEndpoint("GET /v1/plans", "/v1/plans", listOf(Plan));

  // 4. Plan Detail
  await checkEndpoint("GET /v1/plans/214", "/v1/plans/214", Plan);

  // 5. Plan Draft
  await checkEndpoint(
    "POST /v1/plans/draft",
    "/v1/plans/draft",
    Plan,
    {
      method: "POST",
      body: JSON.stringify({ ward: "ward-084" }),
    }
  );

  // 6. Plan Compare
  await checkEndpoint("GET /v1/plans/214/compare", "/v1/plans/214/compare", PlanComparison);

  // 7. Apply Suggestion
  await checkEndpoint(
    "POST /v1/plans/214/suggestions/com-01/apply",
    "/v1/plans/214/suggestions/com-01/apply",
    Plan,
    { method: "POST" }
  );

  // 8. Request Changes
  await checkEndpoint(
    "POST /v1/plans/214/request-changes",
    "/v1/plans/214/request-changes",
    Plan,
    {
      method: "POST",
      body: JSON.stringify({ note: "Please avoid schools during morning recess" }),
    }
  );

  // 9. Approve Plan
  await checkEndpoint(
    "POST /v1/plans/214/approve",
    "/v1/plans/214/approve",
    Plan,
    {
      method: "POST",
      body: JSON.stringify({ note: "Approved with auditor recommendations" }),
    }
  );

  // 10. Fleet Devices
  await checkEndpoint("GET /v1/devices", "/v1/devices", AssetList);

  // 11. Impact List
  await checkEndpoint("GET /v1/impact", "/v1/impact", InterventionList);

  // 12. Impact Library
  await checkEndpoint("GET /v1/impact/library", "/v1/impact/library", listOf(EffectLibraryRow));

  // 13. Alerts
  await checkEndpoint("GET /v1/alerts", "/v1/alerts", AlertList);

  // 14. Driver Route
  await checkEndpoint("GET /v1/driver/route?asset=T-12", "/v1/driver/route?asset=T-12", DriverRoute);

  console.log("\n=======================================================");
  console.log("  ALL 14 BACKEND ENDPOINTS PASSED ZOD CONTRACT VALIDATION!  ");
  console.log("=======================================================\n");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
