// JSX typings for the vendored design web components (src/lib/visuals/*.js)
import type { CSSProperties, Ref } from "react";

type Base = { style?: CSSProperties; className?: string; ref?: Ref<HTMLElement>; children?: React.ReactNode };
type Attr = string | number | boolean | undefined;

declare module "react" {
  namespace JSX {
    interface IntrinsicElements {
      "hawa-gl": Base & {
        theme?: "light" | "dark"; mode?: "live" | "plan" | "usual" | "donor"; hour?: Attr; mix?: Attr; threshold?: Attr;
        layers?: string; assets?: string; selected?: string; center?: string; zoom?: Attr; pitch?: Attr; bearing?: Attr;
        extrude?: ""; hscale?: Attr; labels?: "full" | "major" | "sel" | "none"; maxlabels?: Attr; attrib?: "none";
        "attrib-bottom"?: Attr; interactive?: "false"; spin?: ""; basemap?: string; cooperative?: "";
      };
      "px-sky": Base & { scroll?: "" };
      "px-skyline": Base & { stage?: Attr; seed?: Attr };
      "px-scene": Base & { kind: string; stage?: Attr };
      "vx-city": Base & { haze?: Attr };
      "vx-pod": Base & { scrub?: "" };
      "vx-model": Base & { kind: string };
    }
  }
}
export {};
