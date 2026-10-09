// pixel AQI chip (labels AQI vs PM2.5 explicitly)
import { aqiBandIndex, bandColor, BANDS, pm25BandIndex } from "@hawa/contracts";
import { clsx } from "clsx";

type Props = {
  place: string;
  value: number;
  /** What `value` is. The chip always spells the unit out so AQI and µg/m³ are never confused. */
  kind: "aqi" | "pm25";
  size?: "sm" | "lg";
  blink?: boolean;
  title?: string;
  className?: string;
};

export function AqiChip({ place, value, kind, size = "sm", blink = true, title, className }: Props) {
  const i = kind === "aqi" ? aqiBandIndex(value) : pm25BandIndex(value);
  const band = BANDS[i]!.toUpperCase();
  const label = kind === "aqi" ? `AQI ${value}` : `PM2.5 ${value}`;
  const dark = i <= 1 || i >= 3;
  return (
    <span
      title={title}
      className={clsx(
        "inline-flex flex-none items-center whitespace-nowrap font-pixel",
        size === "sm" ? "pixel-clip h-[26px] gap-1.5 px-[9px] text-[10.5px]" : "pixel-clip-lg h-[30px] gap-2 px-3 text-xs",
        title && "cursor-help",
        className,
      )}
      style={{ background: bandColor(i), color: dark ? "#FFFFFF" : "#0B1215" }}
    >
      <i className={clsx("bg-current", size === "sm" ? "size-[5px]" : "size-1.5", blink && "animate-blink")} />
      {place.toUpperCase()} · {label} · {band}
    </span>
  );
}

/** Small square swatch for a PM2.5 value (lists, legends). */
export function BandSwatch({ pm25, muted, className }: { pm25: number; muted?: boolean; className?: string }) {
  return <i className={clsx("inline-block size-[9px] flex-none rounded-sm", className)} style={{ background: muted ? "#B7B2A8" : bandColor(pm25BandIndex(pm25)) }} />;
}
