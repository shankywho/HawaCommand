"use client";
import { useMemo } from "react";
// SCREEN A Live Map: headline sentence, map, hotspot list <-> detail panel
import { HotspotDetail } from "@/components/hotspots/HotspotDetail";
import { HotspotList } from "@/components/hotspots/HotspotList";
import { HawaMap } from "@/components/map/HawaMap";
import { Legend } from "@/components/map/Legend";
import { LayerToggles, WindChip } from "@/components/map/LayerToggles";
import { atHour, layersFor, toMapStations } from "@/components/map/layers";
import { TimeScrubber } from "@/components/map/TimeScrubber";
import { Screen } from "@/components/shell/Screen";
import { QueryError } from "@/components/ui/Skeleton";
import { useWardHotspots } from "@/hooks/useHotspots";
import { addHours, dayTime, now } from "@/lib/time";
import { useConsole } from "@/stores/console";

export default function MapPage() {
  const { hour, setHour, thresholdUgm3, layers, selectedHotspot, selectHotspot } = useConsole();
  const q = useWardHotspots(0);
  const raw = q.data?.items;
  const items = useMemo(() => atHour(raw ?? [], hour), [raw, hour]);
  const sel = items.find((h) => h.cellId === selectedHotspot);

  const mapLayers = layersFor(layers);
  const stations = useMemo(() => (items.length ? toMapStations(items) : undefined), [items]);
  const top = [...items].sort((a, b) => b.pm25 - a.pm25).slice(0, 3).map((h) => h.place);
  const headline = top.length === 3 ? `${top[0]}, ${top[1]} and ${top[2]} need action first.` : "Loading the current hotspots…";

  return (
    <Screen
      headline={headline}
      aside={
        q.error ? <QueryError error={q.error} /> :
        sel ? <HotspotDetail h={sel} hour={hour} onBack={() => selectHotspot(null)} /> :
        <HotspotList items={items} thresholdUgm3={thresholdUgm3} hourShort={hour === 0 ? "now" : dayTime(addHours(now(), hour))} onPick={selectHotspot} />
      }
    >
      <div className="relative min-h-0 flex-1" data-screen-label="Map">
        <HawaMap
          layers={mapLayers}
          hour={hour}
          thresholdUgm3={thresholdUgm3}
          maxLabels={3}
          attributionBottom={74}
          assets={sel?.assets}
          selected={sel?.cellId}
          labels={sel ? "sel" : "major"}
          stations={stations}
          onHotspotClick={selectHotspot}
        />
        <LayerToggles />
        <WindChip />
        <Legend thresholdUgm3={thresholdUgm3} />
        <TimeScrubber hour={hour} onChange={setHour} />
      </div>
    </Screen>
  );
}
