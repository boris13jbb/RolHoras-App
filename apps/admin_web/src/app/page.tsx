"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { apiFetch, loadSession, type Session } from "@/lib/api";

type Org = {
  id: string;
  name: string;
  slug: string;
  role?: string;
};

export default function HomePage() {
  const [session, setSession] = useState<Session | null>(null);
  const [orgs, setOrgs] = useState<Org[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [health, setHealth] = useState<string>("…");

  useEffect(() => {
    const s = loadSession();
    setSession(s);
    apiFetch<{ status: string }>("/health")
      .then((h) => setHealth(h.status))
      .catch(() => setHealth("offline"));
    if (s) {
      apiFetch<Org[]>("/api/v1/organizations", { token: s.accessToken })
        .then(setOrgs)
        .catch((e: Error) => setError(e.message));
    }
  }, []);

  return (
    <section>
      <h1 className="hero-title">Panel empresarial</h1>
      <p className="lead">
        Administra organizaciones, documentos de rol, trabajos de procesamiento, auditoría y
        suscripciones. La descarga automática de Gmail se gestiona en el backend.
      </p>
      <div className="grid">
        <div className="metric">
          <span className="muted">API</span>
          <strong>{health}</strong>
        </div>
        <div className="metric">
          <span className="muted">Sesión</span>
          <strong>{session ? session.email : "Sin iniciar"}</strong>
        </div>
        <div className="metric">
          <span className="muted">Organizaciones</span>
          <strong>{orgs.length}</strong>
        </div>
      </div>
      {!session && (
        <p style={{ marginTop: "1.5rem" }}>
          <Link className="btn" href="/login">
            Crear sesión de desarrollo
          </Link>
        </p>
      )}
      {error && <p className="error">{error}</p>}
      {orgs.length > 0 && (
        <div className="panel" style={{ marginTop: "1.5rem" }}>
          <h2>Tus organizaciones</h2>
          <table className="table">
            <thead>
              <tr>
                <th>Nombre</th>
                <th>Slug</th>
                <th>Rol</th>
              </tr>
            </thead>
            <tbody>
              {orgs.map((o) => (
                <tr key={o.id}>
                  <td>{o.name}</td>
                  <td>{o.slug}</td>
                  <td>
                    <span className="badge">{o.role || "—"}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}
