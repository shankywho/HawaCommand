// one console screen: headline sentence on top, main area, optional right-hand aside
import { clsx } from "clsx";

export function Screen({ headline, aside, asideClassName, children }: {
  headline: React.ReactNode;
  aside?: React.ReactNode;
  asideClassName?: string;
  children: React.ReactNode;
}) {
  return (
    <>
      <div className="flex-none border-b border-line bg-paper px-[clamp(20px,2.4vw,40px)] py-3.5">
        <h1 key={String(headline)} className="m-0 animate-[pageIn_.4s_cubic-bezier(.2,.7,.2,1)_both] text-balance text-[clamp(19px,1.5vw,24px)] font-semibold leading-[1.3] tracking-[-.015em]">{headline}</h1>
      </div>
      <div className="flex min-h-0 flex-1">
        <div className="relative flex min-h-0 min-w-0 flex-1 animate-[pageIn_.45s_cubic-bezier(.2,.7,.2,1)_both] flex-col">{children}</div>
        {aside && (
          <aside className={clsx("relative flex w-[320px] min-w-0 flex-none animate-[asideIn_.5s_cubic-bezier(.2,.7,.2,1)_both] flex-col overflow-auto border-l border-line bg-white min-[1180px]:w-[360px] min-[1600px]:w-[420px]", asideClassName)}>
            {aside}
          </aside>
        )}
      </div>
    </>
  );
}

export function PanelHead({ title, sub, children }: { title: React.ReactNode; sub?: React.ReactNode; children?: React.ReactNode }) {
  return (
    <div className="panel-head flex flex-col gap-[3px]">
      <span className="text-base font-semibold">{title}</span>
      {sub && <span className="text-[13.5px] text-muted">{sub}</span>}
      {children}
    </div>
  );
}

export function Fact({ k, children, title }: { k: React.ReactNode; children: React.ReactNode; title?: string }) {
  return (
    <div className="fact-row">
      <span className="text-muted">{k}</span>
      <span title={title} className={clsx("font-medium", title && "cursor-help")}>{children}</span>
    </div>
  );
}
