"use client";

import { FormEvent, useEffect, useState } from "react";
import Link from "next/link";
import { apiFetch, loadSession, type Session } from "@/lib/api";

type PdfStatus = { configured: boolean };
type GmailFilters = {
  sender_filter?: string | null;
  subject_pattern?: string | null;
  connected: boolean;
  email_address?: string | null;
};

export default function SettingsPage() {
  const [session, setSession] = useState<Session | null>(null);
  const [pdfConfigured, setPdfConfigured] = useState(false);
  const [password, setPassword] = useState("");
  const [sender, setSender] = useState("");
  const [subject, setSubject] = useState("");
  const [gmailConnected, setGmailConnected] = useState(false);
  const [gmailEmail, setGmailEmail] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function reload(s: Session) {
    const pdf = await apiFetch<PdfStatus>(
      `/api/v1/settings/pdf-password?organization_id=${s.organizationId}`,
      { token: s.accessToken },
    );
    setPdfConfigured(pdf.configured);
    try {
      const filters = await apiFetch<GmailFilters>(
        `/api/v1/settings/gmail-filters?organization_id=${s.organizationId}`,
        { token: s.accessToken },
      );
      setSender(filters.sender_filter || "");
      setSubject(filters.subject_pattern || "");
      setGmailConnected(filters.connected);
      setGmailEmail(filters.email_address || null);
    } catch {
      setGmailConnected(false);
    }
  }

  useEffect(() => {
    const s = loadSession();
    setSession(s);
    if (!s) {
      setError("Inicia sesión primero en Sesión.");
      return;
    }
    reload(s).catch((e: Error) => setError(e.message));
  }, []);

  async function savePassword(e: FormEvent) {
    e.preventDefault();
    if (!session) return;
    setLoading(true);
    setError(null);
    setMessage(null);
    try {
      await apiFetch(`/api/v1/settings/pdf-password?organization_id=${session.organizationId}`, {
        method: "PUT",
        token: session.accessToken,
        body: JSON.stringify({ password }),
      });
      setPassword("");
      setPdfConfigured(true);
      setMessage("Contraseña del PDF guardada.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error al guardar contraseña");
    } finally {
      setLoading(false);
    }
  }

  async function deletePassword() {
    if (!session) return;
    if (!confirm("¿Eliminar la contraseña del PDF?")) return;
    setLoading(true);
    try {
      await apiFetch(`/api/v1/settings/pdf-password?organization_id=${session.organizationId}`, {
        method: "DELETE",
        token: session.accessToken,
      });
      setPdfConfigured(false);
      setMessage("Contraseña eliminada.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error al eliminar");
    } finally {
      setLoading(false);
    }
  }

  async function saveFilters(e: FormEvent) {
    e.preventDefault();
    if (!session) return;
    setLoading(true);
    setError(null);
    setMessage(null);
    try {
      const data = await apiFetch<GmailFilters>(
        `/api/v1/settings/gmail-filters?organization_id=${session.organizationId}`,
        {
          method: "PUT",
          token: session.accessToken,
          body: JSON.stringify({
            sender_filter: sender,
            subject_pattern: subject,
          }),
        },
      );
      setSender(data.sender_filter || "");
      setSubject(data.subject_pattern || "");
      setMessage("Filtros de Gmail guardados.");
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "Conecta Gmail primero y luego configura el remitente.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <section>
      <h1 className="hero-title">Ajustes</h1>
      <p className="lead">
        Configura la contraseña de los PDFs de nómina y el correo remitente que envía el rol.
      </p>

      {error && <p className="error">{error}</p>}
      {message && <p className="muted">{message}</p>}

      <div className="panel stack" style={{ marginBottom: "1rem" }}>
        <h2>Contraseña del PDF</h2>
        <p className="muted">
          Estado: {pdfConfigured ? "Guardada (cifrada en el servidor)" : "No configurada"}
        </p>
        <form className="stack" onSubmit={savePassword}>
          <label>
            Contraseña
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="La que pide el PDF al abrirlo"
              required
            />
          </label>
          <div style={{ display: "flex", gap: "0.75rem", flexWrap: "wrap" }}>
            <button className="btn" type="submit" disabled={loading || !session}>
              Guardar contraseña
            </button>
            <button
              className="btn secondary"
              type="button"
              disabled={loading || !pdfConfigured}
              onClick={deletePassword}
            >
              Eliminar
            </button>
          </div>
        </form>
      </div>

      <div className="panel stack">
        <h2>Remitente de Gmail</h2>
        <p className="muted">
          {gmailConnected
            ? `Cuenta conectada: ${gmailEmail || "—"}`
            : "Aún no hay Gmail conectado."}{" "}
          {!gmailConnected && (
            <Link href="/gmail">Ir a conectar Gmail</Link>
          )}
        </p>
        <form className="stack" onSubmit={saveFilters}>
          <label>
            Correo del remitente (quien envía el rol)
            <input
              type="email"
              value={sender}
              onChange={(e) => setSender(e.target.value)}
              placeholder="ej. nomina@empresa.com"
            />
          </label>
          <label>
            Patrón de asunto (opcional)
            <input
              type="text"
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              placeholder="ej. rol.*pago"
            />
          </label>
          <button className="btn" type="submit" disabled={loading || !session || !gmailConnected}>
            Guardar remitente
          </button>
        </form>
      </div>
    </section>
  );
}
