"use client";

import { useEffect, useState } from "react";
import { API_URL, apiFetch, loadSession } from "@/lib/api";

type Status = {
  connected: boolean;
  status: string;
  email_address?: string;
  last_sync_at?: string;
  watch_expiration?: string;
  last_error_message?: string;
};

export default function GmailPage() {
  const [status, setStatus] = useState<Status | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function refresh() {
    const s = loadSession();
    if (!s) {
      setError("Inicia sesión primero");
      return;
    }
    const data = await apiFetch<Status>(
      `/api/v1/integrations/gmail/status?organization_id=${s.organizationId}`,
      { token: s.accessToken },
    );
    setStatus(data);
  }

  useEffect(() => {
    refresh().catch((e: Error) => setError(e.message));
  }, []);

  async function connect() {
    const s = loadSession();
    if (!s) return;
    try {
      const data = await apiFetch<{ authorization_url: string }>(
        `/api/v1/integrations/gmail/authorize?organization_id=${s.organizationId}`,
        { token: s.accessToken },
      );
      window.location.href = data.authorization_url;
    } catch (e) {
      setError(e instanceof Error ? e.message : "Error");
    }
  }

  async function syncNow() {
    const s = loadSession();
    if (!s) return;
    try {
      const data = await apiFetch<{ message: string }>(
        `/api/v1/integrations/gmail/sync?organization_id=${s.organizationId}`,
        { method: "POST", token: s.accessToken },
      );
      setMessage(data.message);
      await refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Error");
    }
  }

  async function disconnect() {
    const s = loadSession();
    if (!s) return;
    if (!confirm("¿Desconectar Gmail?")) return;
    await apiFetch(`/api/v1/integrations/gmail?organization_id=${s.organizationId}`, {
      method: "DELETE",
      token: s.accessToken,
    });
    setMessage("Gmail desconectado");
    await refresh();
  }

  return (
    <section>
      <h1 className="hero-title">Gmail</h1>
      <p className="lead">
        OAuth offline en el backend ({API_URL}). El refresh token nunca llega al navegador.
      </p>
      {error && <p className="error">{error}</p>}
      {message && <p className="muted">{message}</p>}
      <div className="panel stack">
        <p>
          Estado: <span className="badge">{status?.status || "desconocido"}</span>
        </p>
        <p>Cuenta: {status?.email_address || "—"}</p>
        <p>Última sincronización: {status?.last_sync_at || "—"}</p>
        <p>Watch expira: {status?.watch_expiration || "—"}</p>
        {status?.last_error_message && <p className="error">{status.last_error_message}</p>}
        <div style={{ display: "flex", gap: "0.75rem", flexWrap: "wrap" }}>
          <button className="btn" type="button" onClick={connect}>
            Conectar Gmail
          </button>
          <button className="btn secondary" type="button" onClick={syncNow}>
            Sincronizar ahora
          </button>
          <button className="btn secondary" type="button" onClick={disconnect}>
            Desconectar
          </button>
        </div>
      </div>
    </section>
  );
}
