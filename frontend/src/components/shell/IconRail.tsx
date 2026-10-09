"use client";
// labelled icon rail: collapses to icons below 1320px unless the officer pins it open
import { BadgeCheck, Bell, Columns2, GitPullRequest, Map, PanelLeftClose, PanelLeftOpen, Settings, TrendingUp, Truck, type LucideIcon } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useWardHotspots } from "@/hooks/useHotspots";
import { usePlans } from "@/hooks/usePlan";
import { useConsole } from "@/stores/console";

export const NAV: { href: string; icon: LucideIcon; label: string }[] = [
  { href: "/map", icon: Map, label: "Map" },
  { href: "/forecast", icon: TrendingUp, label: "Forecast" },
  { href: "/plans", icon: GitPullRequest, label: "Plans" },
  { href: "/what-if", icon: Columns2, label: "What-If" },
  { href: "/impact", icon: BadgeCheck, label: "Impact" },
  { href: "/fleet", icon: Truck, label: "Fleet" },
  { href: "/alerts", icon: Bell, label: "Alerts" },
];

const item = "relative flex h-[38px] items-center gap-3 whitespace-nowrap rounded-lg px-2.5 text-left text-sm font-medium hover:bg-hover hover:text-ink";

export function IconRail({ open }: { open: boolean }) {
  const path = usePathname();
  const { setRailOpen, settingsOpen, setSettings } = useConsole();
  const plans = usePlans();
  const worst = useWardHotspots(0).data?.items.reduce<{ place: string; pm25: number } | null>((m, h) => (!m || h.pm25 > m.pm25 ? h : m), null);
  const activeIdx = NAV.findIndex((n) => path.startsWith(n.href));
  const pending = plans.data?.items.filter((p) => p.status === "draft" || p.status === "changes_requested").length ?? 0;

  return (
    <nav className="relative col-start-1 row-start-2 flex min-w-0 flex-col gap-0.5 overflow-hidden border-r border-line bg-white px-2 py-2.5">
      {/* one pill slides between the screens instead of each item snapping */}
      {activeIdx >= 0 && <i className="absolute left-2 right-2 top-2.5 h-[38px] rounded-lg bg-teal/[.09] transition-transform duration-300 ease-[cubic-bezier(.2,.7,.2,1)]" style={{ transform: `translateY(${activeIdx * 40}px)` }} />}
      {activeIdx >= 0 && <i className="absolute left-0 top-2.5 h-[38px] w-[3px] rounded-r bg-teal transition-transform duration-300 ease-[cubic-bezier(.2,.7,.2,1)]" style={{ transform: `translateY(${activeIdx * 40}px)` }} />}
      {NAV.map(({ href, icon: Icon, label }) => {
        const active = path.startsWith(href);
        return (
          <Link key={href} href={href} title={label} aria-label={label} className={item} style={{ color: active ? "#0F766E" : "#4A555B" }}>
            <Icon size={18} strokeWidth={1.75} className="flex-none" />
            {open && <span className="flex-1">{label}</span>}
            {href === "/plans" && pending > 0 && (
              <span className="absolute left-[22px] top-[5px] grid h-[15px] min-w-[15px] place-items-center rounded-lg bg-ink px-1 text-[10px] font-semibold text-white">{pending}</span>
            )}
          </Link>
        );
      })}
      <div className="flex-1" />
      {worst && (
        <div title={`Worst hotspot now: ${worst.place}, PM2.5 ${worst.pm25}`} className="mb-1 flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-[12.5px]">
          <span className="relative grid size-[18px] flex-none place-items-center">
            <i className="absolute size-2 animate-[ping_1.8s_ease-out_infinite] rounded-full bg-teal" />
            <i className="relative size-2 rounded-full bg-teal" />
          </span>
          {open && (
            <span className="flex min-w-0 flex-col leading-tight">
              <span className="text-muted-2">Live · worst now</span>
              <span className="truncate font-mono font-medium text-ink">{worst.pm25} µg/m³</span>
            </span>
          )}
        </div>
      )}
      <button onClick={() => setSettings(!settingsOpen)} title="Settings" className={`${item} text-muted ${settingsOpen ? "bg-hover" : ""}`}>
        <Settings size={18} strokeWidth={1.75} className="flex-none" />
        {open && <span>Settings</span>}
      </button>
      <button onClick={() => setRailOpen(!open)} title={open ? "Collapse" : "Expand"} className={`${item} text-muted`}>
        {open ? <PanelLeftClose size={18} strokeWidth={1.75} /> : <PanelLeftOpen size={18} strokeWidth={1.75} />}
        {open && <span>Collapse</span>}
      </button>
    </nav>
  );
}
