import { useSyncExternalStore } from "react";

export function useMediaQuery(q: string, serverValue = true) {
  return useSyncExternalStore(
    (cb) => {
      const m = matchMedia(q);
      m.addEventListener("change", cb);
      return () => m.removeEventListener("change", cb);
    },
    () => matchMedia(q).matches,
    () => serverValue,
  );
}
