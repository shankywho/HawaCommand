// console shell: header (ward picker, AQI chip, search, clock), labelled icon rail, auth guard
import { AuthGuard } from "@/components/shell/AuthGuard";
import { ConsoleShell } from "@/components/shell/ConsoleShell";

export default function ConsoleLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard>
      <ConsoleShell>{children}</ConsoleShell>
    </AuthGuard>
  );
}
