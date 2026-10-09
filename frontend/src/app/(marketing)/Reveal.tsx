"use client";
// fade/slide a block in once as it scrolls into view; content is fully visible without JS, on first paint and with reduced motion
import { useEffect, useRef, useState } from "react";

const FROM = { up: "translate-y-6", left: "-translate-x-8", right: "translate-x-8" } as const;

export function Reveal({ children, className = "", from = "up", delay = 0 }: { children: React.ReactNode; className?: string; from?: keyof typeof FROM; delay?: number }) {
  const ref = useRef<HTMLDivElement>(null);
  const [hidden, setHidden] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el || matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    if (el.getBoundingClientRect().top < innerHeight * 0.92) return;
    setHidden(true);
    const io = new IntersectionObserver(([e]) => {
      if (e?.isIntersecting) {
        setHidden(false);
        io.disconnect();
      }
    }, { threshold: 0.06, rootMargin: "0px 0px -6% 0px" });
    io.observe(el);
    return () => io.disconnect();
  }, []);

  return (
    <div ref={ref} style={{ transitionDelay: hidden ? "0ms" : `${delay}ms` }} className={`${className} transition-[opacity,transform] duration-[900ms] ease-[cubic-bezier(.2,.7,.2,1)] ${hidden ? `${FROM[from]} opacity-0` : ""}`}>
      {children}
    </div>
  );
}
