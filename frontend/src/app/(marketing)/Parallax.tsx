"use client";
// moves its children at a fraction of scroll speed (landing hero); static with reduced motion
import { useEffect, useRef } from "react";

export function Parallax({ speed = 0.12, className = "", children }: { speed?: number; className?: string; children: React.ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el || matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    let raf = 0;
    const on = () => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        const y = scrollY;
        if (y < innerHeight * 1.4) el.style.transform = `translate3d(0, ${(y * speed).toFixed(1)}px, 0)`;
      });
    };
    addEventListener("scroll", on, { passive: true });
    return () => { removeEventListener("scroll", on); cancelAnimationFrame(raf); };
  }, [speed]);
  return <div ref={ref} className={`will-change-transform ${className}`}>{children}</div>;
}
