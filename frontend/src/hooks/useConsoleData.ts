// query hooks for the remaining console screens (forecast, fleet, impact, alerts, driver)
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { liveQuery } from "@/lib/live";

export const useForecast = (ward?: string) => useQuery({ queryKey: ["forecast", ward], queryFn: () => api.forecast(ward), placeholderData: keepPreviousData });
export const useFleet = () => useQuery({ queryKey: ["devices"], queryFn: api.devices, ...liveQuery });
export const useInterventions = () => useQuery({ queryKey: ["impact"], queryFn: api.impact.list });
export const useEffectLibrary = () => useQuery({ queryKey: ["impact", "library"], queryFn: api.impact.library });
export const useAlerts = () => useQuery({ queryKey: ["alerts"], queryFn: api.alerts });
export const useDriverRoute = (asset: string) => useQuery({ queryKey: ["driver", asset], queryFn: () => api.driverRoute(asset) });
