"use client";
import { Navigation } from "lucide-react";
import { useConsole } from "@/stores/console";
import { LAYER_TOGGLES } from "./layers";

export function LayerToggles() {
  const { layers, toggleLayer } = useConsole();
  return (
    <div className="absolute left-3 top-3 flex max-w-[calc(100%-200px)] flex-wrap gap-0.5 rounded-lg border border-line bg-white p-[3px]">
      {LAYER_TOGGLES.map(({ key, icon: Icon, label }) => (
        <button
          key={key}
          onClick={() => toggleLayer(key)}
          aria-pressed={layers[key]}
          className={`flex h-7 items-center gap-1.5 whitespace-nowrap rounded-md px-2.5 text-[13px] font-medium hover:text-ink ${layers[key] ? "bg-hover text-ink" : "text-muted"}`}
        >
          <Icon size={14} />
          {label}
        </button>
      ))}
    </div>
  );
}

export function WindChip({ text = "Wind NW · 2.1 m/s" }: { text?: string }) {
  return (
    <span className="absolute right-3 top-3 flex h-[34px] items-center gap-[7px] whitespace-nowrap rounded-lg border border-line bg-white px-[11px] text-[13px]">
      <Navigation size={13} />
      {text}
    </span>
  );
}
