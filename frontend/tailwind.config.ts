// design tokens from Claude Design: paper #FAF9F6, ink #0B1215, teal #0F766E, CPCB data colours (data only)
import type { Config } from "tailwindcss";

export default {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        paper: "#FAF9F6",
        ink: { DEFAULT: "#0B1215", 2: "#1C272C" },
        muted: { DEFAULT: "#4A555B", 2: "#5F6B70", 3: "#3B474D" },
        line: { DEFAULT: "#E6E3DC", soft: "#F0EDE6", strong: "#CFCAC0" },
        hover: "#F4F2ED",
        skeleton: "#EEEBE4",
        teal: { DEFAULT: "#0F766E", dark: "#0B5E58", bright: "#2DD4BF", tint: "rgba(15,118,110,.06)" },
        danger: "#C02A2A",
        sand: "#B39571",
        whatsapp: { bg: "#EFEAE2", out: "#D9FDD3" },
        /** CPCB bands. Data only: never UI chrome. */
        aqi: {
          good: "#1E8A4C",
          satisfactory: "#5E8F1B",
          moderate: "#B8920A",
          poor: "#D0690E",
          verypoor: "#C02A2A",
          severe: "#7F1D3A",
        },
      },
      fontFamily: {
        sans: ["var(--font-geist)", "system-ui", "sans-serif"],
        mono: ["var(--font-geist-mono)", "ui-monospace", "monospace"],
        pixel: ["var(--font-silkscreen)", "monospace"],
        deva: ["var(--font-deva)", "var(--font-geist)", "sans-serif"],
      },
      boxShadow: {
        pop: "0 12px 32px rgba(11,18,21,.14)",
        modal: "0 24px 64px rgba(11,18,21,.2)",
        sel: "inset 2px 0 0 #0F766E",
        add: "inset 2px 0 0 #0B1215",
      },
      keyframes: {
        sk: { "0%,100%": { opacity: ".5" }, "50%": { opacity: "1" } },
        pin: { "0%": { opacity: "0", transform: "translateY(4px)" }, "100%": { opacity: "1", transform: "none" } },
        blink: { "0%": { opacity: "1" }, "100%": { opacity: ".2" } },
      },
      animation: {
        sk: "sk 1.4s ease-in-out infinite",
        pin: "pin .2s ease-out",
        blink: "blink 1.6s steps(2) infinite",
      },
    },
  },
  plugins: [],
} satisfies Config;
