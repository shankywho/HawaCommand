// number/unit formatting, confidence -> High/Medium/Low words
import type { Cause } from "@hawa/contracts";

export const fmtInt = (n: number) => Math.round(n).toLocaleString("en-IN");

/** Signed percent with a true minus sign: −18%, +4%. */
export const fmtPct = (n: number, digits = 0) =>
  `${n > 0 ? "+" : n < 0 ? "−" : ""}${Math.abs(n).toFixed(digits)}%`;

export const fmtRange = ([a, b]: readonly [number, number]) => `${fmtInt(a)}–${fmtInt(b)}`;

export type ConfidenceWord = "High" | "Medium" | "Low";
export const confidenceWord = (v: number): ConfidenceWord => (v >= 0.75 ? "High" : v >= 0.6 ? "Medium" : "Low");
export const confidenceTitle = (v: number) => `Confidence ${v.toFixed(2)}`;

export const UGM3 = "µg/m³";

/** The primary verb for a hotspot depends on its cause: water does not help smoke. */
export const CAUSE_VERB: Record<Cause, string> = {
  Dust: "Send sprinkler",
  Traffic: "Divert traffic",
  Burning: "Send inspector",
  "Regional smoke": "Alert schools",
};

export const ago = (iso: string, from: Date) => {
  const s = Math.max(0, Math.round((from.getTime() - new Date(iso).getTime()) / 1000));
  if (s < 60) return `${s} s`;
  const m = Math.round(s / 60);
  if (m < 60) return `${m} min`;
  return `${Math.round(m / 60)} h`;
};

/** "Ward-5" and "ward-084" both read "Ward 5" / "Ward 84"; anything else (All wards, a locality) is left alone. */
export const wardLabel = (w: string) => w.replace(/^ward[-\s]*0*(\d+)$/i, "Ward $1");
export const pollutantLabel = (p: string) => (p === "pm25" ? "PM2.5" : p === "pm10" ? "PM10" : p.toUpperCase());
