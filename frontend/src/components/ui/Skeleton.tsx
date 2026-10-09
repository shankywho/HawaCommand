import { clsx } from "clsx";

export function Skeleton({ className, delay = 0 }: { className?: string; delay?: number }) {
  return <i className={clsx("block rounded bg-skeleton animate-sk", className)} style={{ animationDelay: `${delay}s` }} />;
}

export function QueryError({ error }: { error: unknown }) {
  return (
    <div className="m-6 rounded-lg border border-danger/30 bg-white p-4 text-sm text-danger">
      {error instanceof Error ? error.message : "Something went wrong loading this view."}
    </div>
  );
}
