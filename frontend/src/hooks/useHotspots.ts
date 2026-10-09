// TanStack Query hook
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { liveQuery } from "@/lib/live";
import { ALL_WARDS, useConsole } from "@/stores/console";

export const useHotspots = (hour = 0, ward?: string) =>
  useQuery({
    queryKey: ["hotspots", { hour, ward }],
    queryFn: () => api.hotspots({ hour, ward }),
    placeholderData: keepPreviousData,
    ...(hour === 0 ? liveQuery : {}),
  });

/** Hotspots for the ward chosen in the header (all wards by default). Every hour is derived from each cell's forecast. */
export function useWardHotspots(hour = 0) {
  const ward = useConsole((s) => s.ward);
  return useHotspots(hour, ward === ALL_WARDS ? undefined : ward);
}
