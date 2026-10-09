// root layout, fonts, QueryClientProvider
import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono, Noto_Sans_Devanagari, Silkscreen } from "next/font/google";
import { VisualsLoader } from "@/components/visuals/VisualsLoader";
import { Providers } from "./providers";
import "./globals.css";

const geist = Geist({ subsets: ["latin"], variable: "--font-geist", weight: ["400", "500", "600", "700"] });
const geistMono = Geist_Mono({ subsets: ["latin"], variable: "--font-geist-mono", weight: ["400", "500", "600"] });
const silkscreen = Silkscreen({ subsets: ["latin"], variable: "--font-silkscreen", weight: "400" });
const deva = Noto_Sans_Devanagari({ subsets: ["devanagari"], variable: "--font-deva", weight: ["400", "500", "600", "700"] });

export const metadata: Metadata = {
  title: { default: "HawaCommand", template: "%s · HawaCommand" },
  description: "AI command centre that finds, forecasts and fixes Delhi's pollution hotspots, and proves every fix worked.",
};

export const viewport: Viewport = { themeColor: "#FAF9F6" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${geist.variable} ${geistMono.variable} ${silkscreen.variable} ${deva.variable}`}>
      <body>
        <Providers>{children}</Providers>
        <VisualsLoader />
      </body>
    </html>
  );
}
