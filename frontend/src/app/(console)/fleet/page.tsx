"use client";
// SCREEN F Fleet + HawaTag panel
import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useMemo, useState } from "react";
import { AssetPanel } from "@/components/fleet/AssetPanel";
import { FleetTable } from "@/components/fleet/FleetTable";
import { HawaMap } from "@/components/map/HawaMap";
import { centroid, layersFor } from "@/components/map/layers";
import { useMapStations } from "@/components/map/useMapStations";
import { LayerToggles, WindChip } from "@/components/map/LayerToggles";
import { TimeScrubber } from "@/components/map/TimeScrubber";
import { Screen } from "@/components/shell/Screen";
import { QueryError } from "@/components/ui/Skeleton";
import { useFleet } from "@/hooks/useConsoleData";
import { useConsole } from "@/stores/console";

const ASSET_ICON: Record<string, string> = { sprinkler: "truck", smog_gun: "spray-can", sweeper: "brush", inspection: "users", communicator: "users" };

function Fleet() {
  const params = useSearchParams();
  const [sel, setSel] = useState(params.get("asset") ?? "T-12");
  const { hour, setHour, thresholdUgm3, layers } = useConsole();
  const q = useFleet();
  // the first client render must match the server HTML, so fleet data waits for mount
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  const items = mounted ? (q.data?.items ?? []) : [];
  const a = items.find((x) => x.id === sel) ?? items[0];
  const reporting = items.filter((x) => x.status !== "Offline").length;
  const offline = items.find((x) => x.status === "Offline");
  const stations = useMapStations(hour);
  const fleet = useMemo(
    () => items.flatMap((x) => (x.at ? [{ id: x.id, lon: x.at[0], lat: x.at[1], icon: ASSET_ICON[x.kind] }] : [])),
    [items],
  );
  const silentMin = offline ? Math.max(1, Math.round((Date.now() - Date.parse(offline.lastPingAt)) / 60_000)) : 0;

  return (
    <Screen
      headline={items.length ? `${reporting} of ${items.length} assets are reporting${offline ? `; ${offline.id} has been silent for ${silentMin} minutes` : ""}.` : "Fleet"}
      aside={q.error ? <QueryError error={q.error} /> : a && <AssetPanel a={a} />}
    >
      <div className="relative min-h-0 flex-1" data-screen-label="Fleet">
        <HawaMap layers={layersFor(layers)} hour={hour} thresholdUgm3={thresholdUgm3} maxLabels={3} attributionBottom={74} stations={stations} fleet={fleet} center={a?.at ?? centroid(stations) ?? [77.3, 28.63]} zoom={12} labels="major" />
        <LayerToggles />
        <WindChip />
        <TimeScrubber hour={hour} onChange={setHour} />
      </div>
      <FleetTable items={items} selected={a?.id ?? ""} onPick={setSel} />
    </Screen>
  );
}

export default function FleetPage() {
  return <Suspense><Fleet /></Suspense>;
}
