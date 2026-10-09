// Demo fixtures, lifted from the Claude Design console prototype. Every object is shaped by @hawa/contracts
// so the mock API and the real API are interchangeable. Replace by setting NEXT_PUBLIC_API_URL.
import {
  pm25Band,
  type Alert,
  type Asset,
  type DriverRoute,
  type EffectLibraryRow,
  type Forecast,
  type Hotspot,
  type Intervention,
  type Plan,
  type PlanComparison,
} from "@hawa/contracts";
import { episode, isoAt } from "@/lib/time";

const SCHOOLS = [
  { id: "sch-1", name: "Govt. Sarvodaya Vidyalaya", distanceKm: 0.6, assemblyAt: "08:00" },
  { id: "sch-2", name: "MCD Primary School", distanceKm: 1.1, assemblyAt: "08:00" },
  { id: "sch-3", name: "Sr. Secondary School", distanceKm: 1.8, assemblyAt: "08:00" },
];

type HsRow = [
  id: string, place: string, placeFull: string, ward: string, lon: number, lat: number, pm25: number,
  cause: Hotspot["cause"], conf: number, causeConf: number, suspect: string, exposurePh: number, rank: number, assets: string,
];

const HS: HsRow[] = [
  ["ghazipur", "Ghazipur", "Ghazipur landfill, East Delhi", "East Delhi", 77.329, 28.625, 388, "Burning", 0.74, 0.79, "Landfill edge, open burning", 18420, 1, "I-3,T-12"],
  ["anand", "Anand Vihar", "Anand Vihar ISBT, East Delhi", "East Delhi", 77.316, 28.647, 212, "Dust", 0.82, 0.84, "Unpaved shoulder, ISBT road", 15960, 3, "T-12,ASG-07,SW-03"],
  ["shahdara", "Shahdara", "GT Road, Shahdara", "Shahdara", 77.289, 28.673, 341, "Traffic", 0.69, 0.72, "GT Road corridor, idling HGVs", 16880, 2, "SW-03"],
  ["ito", "ITO", "ITO junction, Central Delhi", "Central", 77.241, 28.629, 296, "Traffic", 0.77, 0.75, "Vikas Marg junction", 11240, 6, "T-07"],
  ["wazirpur", "Wazirpur", "Wazirpur industrial area, North West Delhi", "North West", 77.165, 28.7, 402, "Burning", 0.63, 0.68, "Industrial area, waste pile", 12910, 5, ""],
  ["bawana", "Bawana", "Bawana, North West Delhi", "North West", 77.051, 28.776, 421, "Regional smoke", 0.69, 0.74, "Industrial belt, farm-fire smoke inflow", 9640, 10, ""],
  ["mundka", "Mundka", "Mundka, West Delhi", "West", 77.035, 28.682, 437, "Regional smoke", 0.71, 0.77, "North-west inflow, farm fires upwind", 14020, 4, ""],
  ["jahangirpuri", "Jahangirpuri", "Jahangirpuri, North West Delhi", "North West", 77.171, 28.733, 364, "Dust", 0.66, 0.7, "Construction site, C-block", 10330, 7, ""],
  ["okhla", "Okhla", "Okhla Phase II, South East Delhi", "South East", 77.271, 28.531, 318, "Dust", 0.72, 0.74, "Phase II road works", 8760, 8, "T-19"],
  ["punjabi", "Punjabi Bagh", "Punjabi Bagh, West Delhi", "West", 77.131, 28.674, 279, "Traffic", 0.7, 0.71, "Ring Road flyover queue", 7920, 9, ""],
];

const series = (base: number) =>
  Array.from({ length: 73 }, (_, h) => {
    const p = base * episode(h);
    return { h, p10: Math.round(p * (0.84 - h * 0.0012)), p50: Math.round(p), p90: Math.round(p * (1.14 + h * 0.003)) };
  });

/** Hotspots as the twin would report them at `hour` relative to now. */
export const hotspotsAt = (hour: number): Hotspot[] =>
  HS.map(([cellId, place, placeFull, ward, lon, lat, pm, cause, conf, causeConf, suspect, ph, rank, assets]) => {
    const pm25 = Math.round(pm * episode(hour));
    return {
      cellId, place, placeFull, ward, at: [lon, lat], pm25, band: pm25Band(pm25), cause, conf, causeConf,
      suspectPin: { label: suspect, bearing: "north-west", distanceKm: 1.9, travelMin: 40 },
      exposurePh: Math.round(ph * episode(hour)), rank, schools: SCHOOLS,
      assets: assets ? assets.split(",") : [],
      forecast: series(pm),
    };
  });

export const forecast = (): Forecast => {
  return {
    issuedAt: isoAt(3),
    ward: "East Delhi",
    grap: { stage: "II", likelyAt: isoAt(42), probability: 0.72, headline: "Stage II likely Thursday 08:00 · act by Wednesday evening", actions: ["Daily water sprinkling on primary roads", "Intensify inspections of visibly polluting diesel vehicles", "Suspend outdoor morning assemblies at schools"] },
    series: series(310),
    wards: (
      [
        ["Shahdara", 41200, 452, 0.71], ["East Delhi", 38760, 431, 0.74], ["North West", 33950, 418, 0.66],
        ["West", 29410, 446, 0.69], ["Central", 21880, 389, 0.77], ["South East", 18300, 366, 0.72],
        ["New Delhi", 9720, 301, 0.8], ["South West", 8640, 318, 0.75],
      ] as const
    ).map(([ward, peopleHours, peakPm25, confidence]) => ({ ward, peopleHours, peakPm25, confidence })),
  };
};

export const plan214 = (): Plan => ({
  id: "214",
  ward: "East Delhi",
  window: { start: isoAt(40), end: isoAt(44), label: "Thu 06:00–10:00" },
  status: "draft",
  draftedAt: isoAt(4.5),
  draftedBy: "Planner agent",
  headline: {
    protectedPct: 31, peopleHoursSaved: 12016, likelyRange: [8900, 14700], peopleHoursUsual: 38760,
    peopleHoursPlan: 26744, assetsUsed: 5, assetsTotal: 9, extraKm: 6.4, confidence: 0.78,
  },
  summary:
    "Thursday 08:00 is forecast to hit Stage II, and East Delhi ranks #2 for people exposed. This plan moves T-12 and ASG-07 onto the Anand Vihar dust cell before the peak, with the same assets and shifts.",
  reasoning:
    "A sweeper pre-pass clears the upwind kerbs first, since kerb silt is the suspected source. The three schools in the path get a WhatsApp alert 13 hours ahead. Ghazipur was first given to T-12; the Auditor flagged that water does not help smoke, so it moves to inspection team I-3.",
  groups: [
    {
      asset: "T-12", kind: "sprinkler", label: "Sprinkler truck · Patparganj depot",
      tasks: [
        { id: "t12-1", op: "del", time: "06:00", place: "Mayur Vihar Ph-1 arterial", reason: "Usual route. No hotspot forecast on this segment." },
        { id: "t12-2", op: "del", time: "06:40", place: "NH-24 service road", reason: "Usual route. Lower forecast than the Anand Vihar cell." },
        { id: "t12-3", op: "add", time: "06:10", place: "Anand Vihar ISBT road", cause: "Dust", causeConf: 0.82, reason: "Dust signature, two schools within 400 m at 08:00. Sprinklers on dust in calm air cut PM about 15%." },
        { id: "t12-4", op: "add", time: "06:55", place: "Ghazipur landfill edge", cause: "Burning", causeConf: 0.74, reason: "Highest-exposure cell within reach (18,420 people-hours).", flag: "auditor" },
        { id: "t12-5", op: "add", time: "07:30", place: "Anand Vihar ISBT road, second pass", cause: "Dust", causeConf: 0.82, reason: "The effect fades after about 90 minutes; a second pass holds through the 08:00 peak." },
      ],
    },
    {
      asset: "ASG-07", kind: "smog_gun", label: "Anti-smog gun",
      tasks: [
        { id: "asg-1", op: "del", time: "06:30", place: "Karkardooma court complex", reason: "Fixed post. Low exposure at this hour." },
        { id: "asg-2", op: "add", time: "06:45", place: "Anand Vihar ISBT gate", cause: "Dust", causeConf: 0.82, reason: "Bus queue at peak. The gun only reaches about 200 m, so it sits at the gate itself." },
      ],
    },
    {
      asset: "SW-03", kind: "sweeper", label: "Mechanised sweeper",
      tasks: [
        { id: "sw-1", op: "add", time: "05:45", place: "Vivek Vihar kerbs → Anand Vihar", cause: "Dust", causeConf: 0.77, reason: "Kerb silt is the likely upwind source for the ISBT cell. Sweep before spraying." },
      ],
    },
    {
      asset: "I-3", kind: "inspection", label: "Inspection team",
      tasks: [
        { id: "i3-1", op: "add", time: "06:45", place: "Ghazipur landfill edge · inspect source", cause: "Burning", causeConf: 0.74, reason: "Night-time spike plus a verified citizen photo 300 m away.", flag: "suggested" },
      ],
    },
    {
      asset: "Communicator", kind: "communicator", label: "Alerts",
      tasks: [
        { id: "com-1", op: "add", time: "Wed 19:00", place: "WhatsApp · 3 schools near Anand Vihar · Hindi + English", reason: "Hold assembly indoors. Safest outdoor window 12:30–2:00 PM." },
        { id: "com-2", op: "add", time: "Thu 06:00", place: "SMS · Shahdara ward · traffic advisory", reason: "Avoid GT Road on foot 07:00–10:00." },
      ],
    },
  ],
  comments: [
    {
      id: "aud-1", taskId: "t12-4", status: "open", confidence: 0.91,
      objection: "T-12 is assigned to a burning hotspot near Ghazipur. Water won't help smoke. Reassign to inspection team I-3.",
      suggestion: { remove: "06:55 · T-12 · Ghazipur landfill edge · spray", add: "06:45 · I-3 · Ghazipur landfill edge · inspect source" },
    },
  ],
  checks: [
    { id: "shift", label: "Shift windows respected", detail: "5 of 5 assets", ok: true },
    { id: "water", label: "Water capacity", detail: "9,100 of 14,000 L", ok: true },
    { id: "tool", label: "Right tool for each cause", detail: "T-12 sent to smoke", ok: false },
    { id: "peak", label: "Before the forecast peak", detail: "All tasks before 08:00", ok: true },
    { id: "alerts", label: "School alerts at least 12 h ahead", detail: "13 h", ok: true },
  ],
});

export const compare214 = (): PlanComparison => ({
  planId: "214",
  deltaPct: -31,
  rows: [
    { asset: "T-12", usual: "Mayur Vihar Ph-1 → NH-24", plan: "Anand Vihar ISBT, twice", kmUsual: 14.2, kmPlan: 16.8, reachUsual: "2,140", reachPlan: "9,870", exposureDelta: -3410 },
    { asset: "ASG-07", usual: "Karkardooma (fixed)", plan: "Anand Vihar ISBT gate", kmUsual: 0, kmPlan: 3.1, reachUsual: "610", reachPlan: "4,220", exposureDelta: -1280 },
    { asset: "SW-03", usual: "Patparganj loop", plan: "Vivek Vihar kerbs", kmUsual: 11.0, kmPlan: 9.6, reachUsual: "880", reachPlan: "3,050", exposureDelta: -960 },
    { asset: "I-3", usual: "Ward patrol", plan: "Ghazipur landfill source", kmUsual: 18.5, kmPlan: 12.3, reachUsual: "—", reachPlan: "18,420", exposureDelta: -5260 },
    { asset: "Alerts", usual: "—", plan: "3 schools, 1 ward", kmUsual: null, kmPlan: null, reachUsual: "—", reachPlan: "1,940 children", exposureDelta: -1106 },
  ],
});

const ping = (sec: number) => new Date(Date.parse(isoAt(0)) - sec * 1000).toISOString();
const tag = (on: boolean, lpm: number, litres: number): Asset["tag"] => ({
  tagId: "HTG-0212", fw: "1.4.2", pumpOn: on, flowLpm: lpm, litresThisRun: litres, tankLitres: 1850,
  pm10Before: 418, pm10Now: 349,
  sprayWindows: [{ start: "06:05", end: "06:30" }, { start: "06:45", end: "07:25" }, { start: "07:35", end: "07:50" }],
  tamperIntact: true, signalDbm: -81, trust: 0.94, lastSeq: 88214,
});

export const fleet = (): Asset[] => [
  { id: "T-12", kind: "sprinkler", label: "Sprinkler", task: "Anand Vihar ISBT road · pass 1", status: "Spraying", tagSummary: "Pump on · 38 L/min", lastPingAt: ping(6), at: [77.316, 28.647], simulated: true, tag: tag(true, 38, 1210) },
  { id: "T-07", kind: "sprinkler", label: "Sprinkler", task: "ITO · Vikas Marg", status: "En route", tagSummary: "Pump off", lastPingAt: ping(4), at: [77.241, 28.629], simulated: true, tag: tag(false, 0, 0) },
  { id: "T-19", kind: "sprinkler", label: "Sprinkler", task: "Okhla Phase II", status: "Spraying", tagSummary: "Pump on · 41 L/min", lastPingAt: ping(9), at: [77.271, 28.531], simulated: true, tag: tag(true, 41, 1210) },
  { id: "ASG-07", kind: "smog_gun", label: "Anti-smog gun", task: "Anand Vihar ISBT gate", status: "Spraying", tagSummary: "Fan on · 22 L/min", lastPingAt: ping(3), at: [77.314, 28.646], simulated: true, tag: tag(true, 22, 1210) },
  { id: "SW-03", kind: "sweeper", label: "Sweeper", task: "Vivek Vihar kerbs", status: "Done", tagSummary: "Brush off", lastPingAt: ping(12), at: [77.315, 28.672], simulated: true },
  { id: "I-3", kind: "inspection", label: "Inspection team", task: "Ghazipur landfill edge", status: "On site", tagSummary: "—", lastPingAt: ping(60), at: [77.329, 28.625], simulated: true },
  { id: "T-04", kind: "sprinkler", label: "Sprinkler", task: "Patparganj depot", status: "Refilling", tagSummary: "Pump off", lastPingAt: ping(22), simulated: true, tag: tag(false, 0, 0) },
  { id: "ASG-11", kind: "smog_gun", label: "Anti-smog gun", task: "No task", status: "Offline", tagSummary: "No packet for 38 min", lastPingAt: ping(38 * 60), simulated: true },
];

type IvRow = [string, string, string, string, Hotspot["cause"], number, number, number, number, "Verified" | "Inconclusive" | "No effect"];
const IV: IvRow[] = [
  ["0412", "T-12", "Anand Vihar ISBT road", "Sprinkler", "Dust", -18, -24, -11, 90, "Verified"],
  ["0409", "SW-03", "Vivek Vihar kerbs", "Sweeper", "Dust", -9, -15, -3, 60, "Verified"],
  ["0405", "ASG-07", "Anand Vihar ISBT gate", "Smog gun", "Dust", -6, -13, 1, 40, "Inconclusive"],
  ["0401", "T-07", "ITO · Vikas Marg", "Sprinkler", "Traffic", -2, -8, 4, 20, "No effect"],
  ["0398", "I-3", "Ghazipur landfill edge", "Inspection", "Burning", -27, -35, -18, 180, "Verified"],
  ["0393", "T-19", "Okhla Phase II", "Sprinkler", "Dust", -14, -20, -7, 75, "Verified"],
];

/** Observed vs synthetic control for one intervention, 05:30–09:30 in 5-min steps. */
const impactSeries = (effectPct: number, seed: number) => {
  let s = seed;
  const r = () => ((s = (s * 16807) % 2147483647) / 2147483647);
  return Array.from({ length: 49 }, (_, i) => {
    const control = 402 + i * 0.9 + 14 * Math.sin(i / 5) + (r() - 0.5) * 8;
    const k = i >= 13 && i <= 34 ? Math.min(1, (i - 13) / 2) * (i > 30 ? Math.max(0, (34 - i) / 4) : 1) : 0;
    const observed = control * (1 + (effectPct / 100) * k) + (r() - 0.5) * 8;
    return {
      t: new Date(Date.parse("2026-11-12T05:30:00+05:30") + i * 5 * 60_000).toISOString(),
      observed: Math.round(observed), control: Math.round(control),
      lo: Math.round(control * (0.95 - i * 0.0008)), hi: Math.round(control * (1.05 + i * 0.0008)),
    };
  });
};

export const interventions = (): Intervention[] =>
  IV.map(([id, asset, place, action, cause, effectPct, ciLow, ciHigh, durationMin, verdict], i) => ({
    id, asset, action, place, cause, planId: "214", cellId: `cell-${id}`,
    startedAt: isoAt(-24 - i * 6), simulated: true,
    impact: {
      pollutant: "pm10", effectPct, ciLow, ciHigh, durationMin, method: "synthetic_control", verdict,
      donorCells: [31, 24, 19, 14, 12].map((w, j) => ({ cellId: `donor-${j + 1}`, weight: w / 100 })),
      series: impactSeries(effectPct, 7 + i),
    },
  }));

export const effectLibrary = (): EffectLibraryRow[] =>
  (
    [
      ["Sprinkler", "Dust", "Calm, dry air", -15, [-21, -9], 80, 48],
      ["Sprinkler", "Dust", "Wind over 3 m/s", -6, [-11, -1], 35, 31],
      ["Sprinkler", "Traffic", "Any", -2, [-7, 3], null, 22],
      ["Sweeper", "Dust", "Calm, before spraying", -9, [-14, -4], 60, 19],
      ["Smog gun", "Dust", "Calm, within 200 m", -5, [-10, 0], 40, 27],
      ["Inspection", "Burning", "Night, photo matched", -24, [-32, -15], 180, 12],
      ["Any truck", "Regional smoke", "North-west wind, farm fires", 0, [-4, 3], null, 15],
    ] as const
  ).map(([action, cause, weather, effectPct, ci, durationMin, n]) => ({
    action, cause, weather, effectPct, ci: [ci[0], ci[1]], durationMin, n,
  }));

const HI_SCHOOL =
  "आपके स्कूल के पास कल सुबह 8 बजे PM2.5 लगभग 380 µg/m³ तक पहुँचेगा। प्रार्थना सभा अंदर करें। बाहर के लिए सबसे सुरक्षित समय: दोपहर 12:30–2:00।";

export const alerts = (): Alert[] => [
  { id: "a1", sentAt: isoAt(29), audience: "School", target: "Govt. Sarvodaya Vidyalaya, Anand Vihar", message: "PM2.5 ~380 µg/m³ at 8 AM. Hold assembly indoors.", messageHi: HI_SCHOOL, channel: "WhatsApp", lang: "hi+en", delivered: "3 of 3 read", leadTimeH: 13, draftedBy: "Communicator" },
  { id: "a2", sentAt: isoAt(29), audience: "School", target: "MCD Primary School, Ghazipur", message: "PM2.5 ~380 µg/m³ at 8 AM. Hold assembly indoors.", messageHi: HI_SCHOOL, channel: "WhatsApp", lang: "hi+en", delivered: "3 of 3", leadTimeH: 13, draftedBy: "Communicator" },
  { id: "a3", sentAt: isoAt(29 + 2 / 60), audience: "School", target: "Sr. Secondary School, Mayur Vihar Ph-3", message: "Safest outdoor window 12:30–2:00 PM.", messageHi: HI_SCHOOL, channel: "WhatsApp", lang: "hi", delivered: "2 of 3", leadTimeH: 13, draftedBy: "Communicator" },
  { id: "a4", sentAt: isoAt(40), audience: "Citizens", target: "Shahdara ward · 4,210 subscribers", message: "Traffic fumes high on GT Road. Avoid on foot 07:00–10:00.", channel: "SMS", lang: "hi", delivered: "4,106", leadTimeH: 1, draftedBy: "Communicator" },
  { id: "a5", sentAt: isoAt(-7 - 16 / 60), audience: "Citizen Eyes", target: "Report #C-118 · open burning, Ghazipur", message: "Verified. Inspection team on the way.", channel: "WhatsApp", lang: "hi", delivered: "Read", leadTimeH: null, draftedBy: "Communicator" },
  { id: "a6", sentAt: isoAt(-6 - 48 / 60), audience: "Citizen Eyes", target: "Report #C-118 · open burning, Ghazipur", message: "Resolved at 07:10. Thank you.", channel: "WhatsApp", lang: "hi", delivered: "Read", leadTimeH: null, draftedBy: "Communicator" },
  { id: "a7", sentAt: isoAt(-19.5), audience: "Workers", target: "Okhla delivery riders · partner fleet", message: "Smoke tonight. Wear an N95 on outer routes.", channel: "WhatsApp", lang: "en", delivered: "612", leadTimeH: 14, draftedBy: "Communicator" },
];

export const driverRoute = (asset = "T-12"): DriverRoute => ({
  asset,
  assetLabelHi: "पानी छिड़काव गाड़ी",
  planId: "214",
  dateLabel: "Thu 12 Nov",
  window: "06:00–10:00",
  stops: [
    { n: 1, placeHi: "आनंद विहार ISBT रोड", placeEn: "Anand Vihar ISBT road", actionEn: "spray", from: "06:10", to: "06:50", status: "active" },
    { n: 2, placeHi: "पटपड़गंज डिपो · पानी भरें", placeEn: "Patparganj depot", actionEn: "refill", from: "07:00", to: "07:20", status: "todo" },
    { n: 3, placeHi: "आनंद विहार · दूसरा चक्कर", placeEn: "Anand Vihar · 2nd pass", actionEn: "spray", from: "07:30", to: "08:10", status: "todo" },
  ],
  lastSpray: { placeHi: "आनंद विहार ISBT रोड", litres: 1210, pumpMin: 32, pumpOn: false },
});
