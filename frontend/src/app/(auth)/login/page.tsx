"use client";
// Cognito sign-in (officer role). In demo mode (no pool configured) it goes straight to the console.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { Logo } from "@/components/ui/Logo";
import { AUTH_ENABLED, login } from "@/lib/auth";

export default function LoginPage() {
  const router = useRouter();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!AUTH_ENABLED) return router.push("/map");
    setBusy(true); setError(null);
    try {
      const r = await login(username, password);
      if (r.isSignedIn) router.push("/map");
      else setError(`Additional step required: ${r.nextStep.signInStep}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Sign-in failed");
    } finally {
      setBusy(false);
    }
  };

  const input = "h-10 rounded-md border border-line bg-white px-3 text-sm outline-none focus:border-teal";
  return (
    <main className="grid min-h-screen place-items-center bg-paper p-6">
      <form onSubmit={submit} className="card flex w-[380px] max-w-full flex-col gap-4 p-8">
        <Logo />
        <div>
          <h1 className="m-0 text-xl font-semibold tracking-[-.02em]">Officer sign-in</h1>
          <p className="m-0 mt-1 text-sm text-muted">MCD and DPCC ward officers only.</p>
        </div>
        {AUTH_ENABLED ? (
          <>
            <label className="flex flex-col gap-1.5 text-[13px] text-muted">Username<input className={input} value={username} onChange={(e) => setUsername(e.target.value)} autoComplete="username" required /></label>
            <label className="flex flex-col gap-1.5 text-[13px] text-muted">Password<input className={input} type="password" value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" required /></label>
          </>
        ) : (
          <p className="m-0 rounded-md border border-line bg-paper px-3 py-2.5 text-[13.5px] text-muted">Demo mode: Cognito is not configured, so the console opens without sign-in.</p>
        )}
        {error && <p className="m-0 text-sm text-danger">{error}</p>}
        <button disabled={busy} className="btn btn-lg btn-primary">{busy ? "Signing in…" : AUTH_ENABLED ? "Sign in" : "Open console"}</button>
      </form>
    </main>
  );
}
