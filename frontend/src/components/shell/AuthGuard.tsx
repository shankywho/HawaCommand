"use client";
// Redirects to /login when Cognito is configured and there is no officer session. No-op in demo mode.
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { AUTH_ENABLED, currentOfficer } from "@/lib/auth";

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [ok, setOk] = useState(!AUTH_ENABLED);
  useEffect(() => {
    if (!AUTH_ENABLED) return;
    currentOfficer().then((u) => (u ? setOk(true) : router.replace("/login")));
  }, [router]);
  return ok ? <>{children}</> : null;
}
