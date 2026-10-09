// driver PWA shell: phone-width column, Hindi-first type
export const metadata = { title: "Driver" };

export default function DriverLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-dvh bg-[#EDEBE5] sm:py-6">
      <div className="mx-auto flex min-h-dvh w-full max-w-[420px] flex-col bg-paper sm:min-h-[844px] sm:overflow-hidden sm:rounded-[36px] sm:shadow-[0_20px_50px_rgba(11,18,21,.25)]">
        {children}
      </div>
    </div>
  );
}
