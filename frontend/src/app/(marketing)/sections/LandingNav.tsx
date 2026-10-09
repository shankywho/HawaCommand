"use client";
// sticky nav that shrinks on scroll; its chip shows the worst current hotspot from the same API the console reads
import { useEffect, useState } from "react";
import { AqiChip } from "@/components/ui/AqiChip";
import { LogoMark } from "@/components/ui/Logo";
import { useMediaQuery } from "@/hooks/useMediaQuery";
import { useLandingAir } from "../live";
import { ConsoleCta } from "./ui";

const LINKS = [["causes", "Product"], ["how", "How it works"], ["proof", "Proof"], ["hardware", "Hardware"], ["open", "Open data"]] as const;

export function LandingNav() {
  const wide = useMediaQuery("(min-width: 1080px)");
  const [s, setS] = useState({ y: 0, sec: "" });
  const { top, simulated } = useLandingAir();

  useEffect(() => {
    const on = () => {
      const se = document.scrollingElement || document.documentElement;
      const y = se.scrollTop;
      let sec = "";
      LINKS.forEach(([id]) => { const e = document.getElementById(id); if (e && e.getBoundingClientRect().top < innerHeight * 0.4) sec = id; });
      setS((o) => ((y > 24) !== (o.y > 24) || sec !== o.sec ? { y, sec } : o));
    };
    on();
    addEventListener("scroll", on, { passive: true });
    return () => removeEventListener("scroll", on);
  }, []);

  const c = s.y > 24;

  return (
    <header className="sticky top-0 z-20 h-0 overflow-visible">
      <div className="mx-auto animate-[navIn_.5s_cubic-bezier(.2,.7,.2,1)_both] transition-all duration-[250ms]" style={{ maxWidth: c ? 1120 : 1248, padding: c ? "10px 24px 0" : 0 }}>
        <div
          className="flex items-center gap-2 border bg-paper/95 transition-all duration-[250ms]"
          style={{ paddingLeft: 16, paddingRight: 8, height: c ? 52 : 64, borderRadius: c ? 12 : 0, borderColor: c ? "rgba(11,18,21,.1)" : "transparent", boxShadow: c ? "0 8px 28px rgba(60,40,20,.14)" : "none" }}
        >
          <a href="#top" className="mr-3 flex items-center gap-2.5 !text-ink no-underline">
            <LogoMark spin />
            <span className="whitespace-nowrap text-[15px] font-semibold tracking-[-.01em]">Hawa<span className="text-teal">Command</span></span>
          </a>
          {wide && (
            <nav className="flex gap-0.5 text-sm font-medium">
              {LINKS.map(([id, label]) => {
                const on = s.sec === id;
                return (
                  <a key={id} href={`#${id}`} className="relative flex h-[34px] items-center whitespace-nowrap rounded-[7px] px-3 no-underline transition-colors hover:bg-ink/5 hover:!text-ink" style={{ color: on ? "#0B1215" : "#3B474D", background: on ? "rgba(15,118,110,.07)" : undefined }}>
                    {label}
                    <i className="absolute inset-x-3 bottom-1 h-0.5 origin-left rounded-[1px] bg-teal transition-transform duration-[250ms]" style={{ transform: `scaleX(${on ? 1 : 0})` }} />
                  </a>
                );
              })}
            </nav>
          )}
          <div className="flex-1" />
          {top && (
            <AqiChip
              place="Delhi"
              value={Math.round(top.pm25)}
              kind="pm25"
              className="hidden min-[1280px]:inline-flex"
              title={`Highest hotspot PM2.5 right now (${top.place}) · ${simulated ? "demo data" : "live data"}`}
            />
          )}
          <ConsoleCta size="md" />
        </div>
      </div>
    </header>
  );
}
