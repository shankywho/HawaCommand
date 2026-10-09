// CPCB PM2.5/PM10 breakpoints -> band + colour; AQI vs concentration helpers (never mix units)
import { z } from "zod";

export const BANDS = ["Good", "Satisfactory", "Moderate", "Poor", "Very Poor", "Severe"] as const;
export const Band = z.enum(BANDS);
export type Band = z.infer<typeof Band>;

/** Upper bound (inclusive) of each band, in µg/m³ (24-h CPCB breakpoints). */
export const PM25_BREAKPOINTS = [30, 60, 90, 120, 250] as const;
export const PM10_BREAKPOINTS = [50, 100, 250, 350, 430] as const;
/** Upper bound of each band on the AQI index scale (unitless). */
export const AQI_BREAKPOINTS = [50, 100, 200, 300, 400] as const;

/** Data colours only: never use these for UI chrome. Light theme. */
export const BAND_COLORS = ["#1E8A4C", "#5E8F1B", "#B8920A", "#D0690E", "#C02A2A", "#7F1D3A"] as const;
export const BAND_COLORS_DARK = ["#3FB871", "#9CCB4E", "#E8C53A", "#F08C35", "#E5484D", "#C43A6B"] as const;

const indexFor = (v: number, bp: readonly number[]) => {
  const i = bp.findIndex((b) => v <= b);
  return i === -1 ? bp.length : i;
};

export const pm25BandIndex = (ugm3: number) => indexFor(ugm3, PM25_BREAKPOINTS);
export const pm10BandIndex = (ugm3: number) => indexFor(ugm3, PM10_BREAKPOINTS);
export const aqiBandIndex = (aqi: number) => indexFor(aqi, AQI_BREAKPOINTS);

export const pm25Band = (ugm3: number): Band => BANDS[pm25BandIndex(ugm3)]!;
export const aqiBand = (aqi: number): Band => BANDS[aqiBandIndex(aqi)]!;
export const bandColor = (i: number, dark = false) => (dark ? BAND_COLORS_DARK : BAND_COLORS)[i]!;

/** A reading always carries its unit so AQI and concentration are never mixed. */
export const Reading = z.discriminatedUnion("unit", [
  z.object({ unit: z.literal("aqi"), value: z.number().nonnegative() }),
  z.object({ unit: z.literal("ugm3"), pollutant: z.enum(["pm25", "pm10"]), value: z.number().nonnegative() }),
]);
export type Reading = z.infer<typeof Reading>;
