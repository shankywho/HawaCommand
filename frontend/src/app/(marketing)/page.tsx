// landing: hero (2-line headline + voxel city), problem, causes, how-it-works map, proof, CTA
import type { Metadata } from "next";
import { Aws, Cost } from "./sections/Aws";
import { Causes } from "./sections/Causes";
import { Footer } from "./sections/Footer";
import { Marquee } from "./Marquee";
import { ScrollRail } from "./ScrollRail";
import { SmoothScroll } from "./SmoothScroll";
import { Hardware } from "./sections/Hardware";
import { Hero } from "./sections/Hero";
import { HowItWorks } from "./sections/HowItWorks";
import { LandingNav } from "./sections/LandingNav";
import { Learned } from "./sections/Learned";
import { Problem } from "./sections/Problem";
import { Proof } from "./sections/Proof";
import { WhatIf } from "./sections/WhatIf";

export const metadata: Metadata = {
  title: { absolute: "HawaCommand · Delhi already owns the machines. We give them a brain." },
  description: "AI command centre that finds, forecasts and fixes Delhi's pollution hotspots street by street, and proves every fix worked.",
  openGraph: {
    title: "HawaCommand",
    description: "Hotspots street by street, sprinklers before the spike, and proof that each fix worked.",
    type: "website",
  },
};

export default function LandingPage() {
  return (
    <div className="overflow-x-clip bg-sand">
      <SmoothScroll />
      <ScrollRail />
      <px-sky scroll="" style={{ position: "fixed", inset: 0, zIndex: 0 }} />
      <div className="relative z-[1]">
        <LandingNav />
        <Hero />
        <Marquee />
        <Problem />
        <Causes />
        <HowItWorks />
        <WhatIf />
        <Proof />
        <Hardware />
        <Learned />
        <Aws />
        <Cost />
        <Footer />
      </div>
    </div>
  );
}
