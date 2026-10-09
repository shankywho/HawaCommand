// live updates: poll every 5s (swap for AppSync / IoT WebSocket later without touching components)
export const LIVE_POLL_MS = 5_000;

/** TanStack Query options for data that should refresh while the console is open. */
export const liveQuery = { refetchInterval: LIVE_POLL_MS, refetchIntervalInBackground: false } as const;
