import Link from "next/link";

export function AppShell({ children }: { children: React.ReactNode }) {
  return (
    <main>
      <header className="appbar">
        <div className="brand">Rol Pagos</div>
        <nav className="nav" aria-label="Principal">
          <Link href="/">Dashboard</Link>
          <Link href="/organizations">Organizaciones</Link>
          <Link href="/documents">Documentos</Link>
          <Link href="/jobs">Trabajos</Link>
          <Link href="/audit">Auditoría</Link>
          <Link href="/billing">Planes</Link>
          <Link href="/gmail">Gmail</Link>
          <Link href="/settings">Ajustes</Link>
          <Link href="/login">Sesión</Link>
        </nav>
      </header>
      {children}
    </main>
  );
}
