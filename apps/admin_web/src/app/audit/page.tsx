"use client";

import { useEffect, useState } from "react";
import { apiFetch, loadSession } from "@/lib/api";

type AuditEvent = {
  id: string;
  action: string;
  resource_type: string;
  resource_id?: string;
  created_at?: string;
};

export default function AuditPage() {
  const [events, setEvents] = useState<AuditEvent[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const s = loadSession();
    if (!s) return;
    apiFetch<AuditEvent[]>(`/api/v1/audit/events?organization_id=${s.organizationId}`, {
      token: s.accessToken,
    })
      .then(setEvents)
      .catch((e: Error) => setError(e.message));
  }, []);

  return (
    <section>
      <h1 className="hero-title">Auditoría</h1>
      {error && <p className="error">{error}</p>}
      <div className="panel">
        <table className="table">
          <thead>
            <tr>
              <th>Acción</th>
              <th>Recurso</th>
              <th>Fecha</th>
            </tr>
          </thead>
          <tbody>
            {events.map((e) => (
              <tr key={e.id}>
                <td>{e.action}</td>
                <td>
                  {e.resource_type} {e.resource_id || ""}
                </td>
                <td>{e.created_at || "—"}</td>
              </tr>
            ))}
            {events.length === 0 && (
              <tr>
                <td colSpan={3} className="muted">
                  Sin eventos.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
