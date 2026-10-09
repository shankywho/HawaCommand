// Zustand: selected hotspot, ward, time, map layers and shell chrome
import { create } from "zustand";

export type LayerKey = "heat" | "hotspots" | "trails" | "trucks" | "schools";

export const ALL_WARDS = "All wards";

type ConsoleState = {
  ward: string;
  hour: number;
  thresholdUgm3: number;
  selectedHotspot: string | null;
  layers: Record<LayerKey, boolean>;
  railOpen: boolean | null;
  paletteOpen: boolean;
  settingsOpen: boolean;
  dark: boolean;
  toast: { title: string; body: string } | null;
  setWard: (w: string) => void;
  setHour: (h: number) => void;
  selectHotspot: (id: string | null) => void;
  toggleLayer: (k: LayerKey) => void;
  setLayers: (l: Record<LayerKey, boolean>) => void;
  setRailOpen: (v: boolean) => void;
  setPalette: (v: boolean) => void;
  setSettings: (v: boolean) => void;
  toggleDark: () => void;
  showToast: (t: ConsoleState["toast"]) => void;
};

export const useConsole = create<ConsoleState>((set) => ({
  ward: ALL_WARDS,
  hour: 0,
  thresholdUgm3: 250,
  selectedHotspot: null,
  layers: { heat: true, hotspots: true, trails: true, trucks: true, schools: true },
  railOpen: null,
  paletteOpen: false,
  settingsOpen: false,
  dark: false,
  toast: null,
  setWard: (ward) => set({ ward }),
  setHour: (hour) => set({ hour }),
  selectHotspot: (selectedHotspot) => set({ selectedHotspot }),
  toggleLayer: (k) => set((s) => ({ layers: { ...s.layers, [k]: !s.layers[k] } })),
  setLayers: (layers) => set({ layers }),
  setRailOpen: (railOpen) => set({ railOpen }),
  setPalette: (paletteOpen) => set({ paletteOpen }),
  setSettings: (settingsOpen) => set({ settingsOpen }),
  toggleDark: () => set((s) => ({ dark: !s.dark })),
  showToast: (toast) => set({ toast }),
}));
