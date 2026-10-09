"use client";
// console chrome: header, rail, settings popover, command palette, toast
import { CircleCheck, Moon, X } from "lucide-react";
import { CommandPalette } from "@/components/ui/CommandPalette";
import { useMediaQuery } from "@/hooks/useMediaQuery";
import { useConsole } from "@/stores/console";
import { ConsoleHeader } from "./ConsoleHeader";
import { IconRail } from "./IconRail";

export function ConsoleShell({ children }: { children: React.ReactNode }) {
  const wide = useMediaQuery("(min-width: 1320px)");
  const { railOpen, dark, toggleDark, settingsOpen, toast, showToast } = useConsole();
  const open = railOpen ?? wide;

  return (
    <div
      className="fixed inset-0 grid min-w-[820px] bg-paper transition-[grid-template-columns] duration-300 ease-out"
      style={{ gridTemplateColumns: `${open ? 168 : 56}px minmax(0,1fr)`, gridTemplateRows: "52px minmax(0,1fr)", filter: dark ? "invert(0.92) hue-rotate(180deg)" : undefined }}
    >
      <ConsoleHeader />
      <IconRail open={open} />
      <main className="col-start-2 row-start-2 flex min-h-0 min-w-0 flex-col">{children}</main>

      {settingsOpen && (
        <div className="fixed bottom-24 left-3 z-[60] flex w-[260px] animate-pin flex-col gap-0.5 rounded-[10px] border border-line bg-white p-2 shadow-pop">
          <button onClick={toggleDark} className="flex h-[38px] items-center gap-2.5 rounded-md px-2.5 text-left text-sm font-medium hover:bg-hover">
            <Moon size={16} />
            <span className="flex-1">Dark mode</span>
            <span className="relative h-[18px] w-8 rounded-[9px] transition-colors" style={{ background: dark ? "#0F766E" : "#CFCAC0" }}>
              <i className="absolute top-0.5 size-3.5 rounded-full bg-white transition-[left]" style={{ left: dark ? 16 : 2 }} />
            </span>
          </button>
        </div>
      )}

      <CommandPalette />

      {toast && (
        <div className="fixed bottom-4 right-[336px] z-40 flex w-80 animate-pin items-start gap-2.5 rounded-[10px] border border-line bg-white px-3.5 py-3 shadow-pop min-[1180px]:right-[376px]">
          <CircleCheck size={17} className="mt-px flex-none text-teal" />
          <div className="flex-1">
            <div className="text-sm font-semibold">{toast.title}</div>
            <div className="mt-0.5 text-[13.5px] leading-[1.45] text-muted">{toast.body}</div>
          </div>
          <button onClick={() => showToast(null)} aria-label="Dismiss" className="text-muted"><X size={15} /></button>
        </div>
      )}
    </div>
  );
}
