import Link from "next/link";

export default function NotFound() {
  return (
    <main className="grid min-h-screen place-items-center p-6">
      <div className="card flex w-[420px] max-w-full flex-col items-center gap-3 p-10 text-center">
        <div className="text-[17px] font-semibold">Page not found</div>
        <Link href="/map" className="btn btn-primary btn-lg">Open the console</Link>
      </div>
    </main>
  );
}
