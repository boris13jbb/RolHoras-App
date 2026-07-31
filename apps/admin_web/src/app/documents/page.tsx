"use client";

import { useEffect, useState } from "react";
import { apiFetch, loadSession } from "@/lib/api";

type Doc = {
  id: string;
  status: string;
  original_filename?: string;
  period_year?: number;
  period_month?: number;
  source: string;
  created_at: string;
};

export default function DocumentsPage() {
  const [docs, setDocs] = useState<Doc[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const s = loadSession();
    if (!s) {
      setError("Inicia sesión primero");
      return;
    }
    apiFetch<Doc[]>(`/api/v1/documents?organization_id=${s.organizationId}`, {
      token: s.accessToken,
    })
      .then(setDocs)
      .catch((e: Error) => setError(e.message));
  }, []);

  return (
    <section>
      <h1 className="hero-title">Documentos</h1>
      <p className="lead">Roles importados por Gmail o carga manual de respaldo.</p>
      {error && <p className="error">{error}</p>}
      <div className="panel">
        <table className="table">
          <thead>
            <tr>
              <th>Archivo</th>
              <th>Origen</th>
              <th>Periodo</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            {docs.map((d) => (
              <tr key={d.id}>
                <td>{d.original_filename || d.id}</td>
                <td>{d.source}</td>
                <td>
                  {d.period_month && d.period_year ? `${d.period_month}/${d.period_year}` : "—"}
                </td>
                <td>
                  <span
                    className={`badge ${
                      d.status === "failed"
                        ? "err"
                        : d.status.includes("review") || d.status.includes("password")
                          ? "warn"
                          : ""
                    }`}
                  >
                    {d.status}
                  </span>
                </td>
              </tr>
            ))}
            {docs.length === 0 && (
              <tr>
                <td colSpan={4} className="muted">
                  Sin documentos todavía.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
