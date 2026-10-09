// pixel "H" tile (stems = the city, bar = the air path, corner pixel = a live sensor) + two-tone wordmark
import { clsx } from "clsx";

/** `spin` keeps its old name: it now makes the sensor pixel in the corner blink. `light` is for dark backgrounds. */
export function LogoMark({ size = 28, spin = false, light = false }: { size?: number; spin?: boolean; light?: boolean }) {
  const tile = light ? "#FAF9F6" : "#0B1215";
  const stem = light ? "#0B1215" : "#FAF9F6";
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" shapeRendering="crispEdges" role="img" aria-label="HawaCommand" className="flex-none">
      <path fill={tile} d="M1 0H15V1H16V15H15V16H1V15H0V1H1Z" />
      <path fill={stem} d="M4 4H6V12H4ZM10 4H12V12H10Z" />
      <path fill={light ? "#0F766E" : "#2DD4BF"} d="M6 7H10V9H6Z" />
      <path className={clsx(spin && "animate-blink")} fill={light ? "#2DD4BF" : "#0F766E"} d="M12 2H14V4H12Z" />
    </svg>
  );
}

export function Logo({ spin, light }: { spin?: boolean; light?: boolean }) {
  return (
    <span className="flex flex-none items-center gap-2.5">
      <LogoMark spin={spin} light={light} />
      <span className="whitespace-nowrap text-[15px] font-semibold tracking-[-.01em]">Hawa<span className={light ? "text-teal-bright" : "text-teal"}>Command</span></span>
    </span>
  );
}
