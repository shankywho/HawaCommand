// cause + asset icon mapping (lucide), so every screen uses the same glyph for the same thing
import {
  Brush, Car, CloudFog, Flame, MessageCircle, SprayCan, Truck, Users, Wind, type LucideIcon,
} from "lucide-react";
import type { AssetKind, Cause } from "@hawa/contracts";

export const CAUSE_ICON: Record<Cause, LucideIcon> = {
  Dust: Wind,
  Traffic: Car,
  Burning: Flame,
  "Regional smoke": CloudFog,
};

export const ASSET_ICON: Record<AssetKind, LucideIcon> = {
  sprinkler: Truck,
  smog_gun: SprayCan,
  sweeper: Brush,
  inspection: Users,
  communicator: MessageCircle,
};
