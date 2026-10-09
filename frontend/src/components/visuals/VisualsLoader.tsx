"use client";
// Registers the design's canvas/map web components once, client-side. Tags rendered before this runs
// upgrade automatically when their element is defined.
import { useEffect } from "react";

declare global {
  interface Window { lucide?: { icons: unknown }; maplibregl?: unknown }
}

let loading: Promise<void> | null = null;

export function loadVisuals() {
  loading ??= (async () => {
    const [{ icons }, maplibre] = await Promise.all([import("lucide"), import("maplibre-gl")]);
    window.lucide = { icons };
    window.maplibregl = maplibre.default;
    // @ts-expect-error vendored plain-JS modules without types
    await import("@/lib/visuals/hawa.js");
    // @ts-expect-error vendored plain-JS modules without types
    await import("@/lib/visuals/hawa-gl.js");
    // @ts-expect-error vendored plain-JS modules without types
    await import("@/lib/visuals/pixel.js");
  })();
  return loading;
}

export function VisualsLoader() {
  useEffect(() => {
    loadVisuals().catch((e) => console.error("[visuals] failed to load", e));
  }, []);
  return null;
}
