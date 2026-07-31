"use client";

import { useEffect, useState } from "react";
import { apiFetch, loadSession } from "@/lib/api";

type Org = { id: string; name: string; slug: string; role?: string; is_personal: boolean };

export default function OrganizationsPage() {
  const [orgs, setOrgs] = useState<Org[]>([]);
  const [name, setName] = useState("");
  const [error, setError] = useState<string | null>(null);

  async function reload(token: string) {
    const data = await apiFetch<Org[]>("/api/v1/organizations", { token });
    setOrgs(data);
  }

  useEffect(() => {
    const s = loadSession();
    if (!s) return;
    reload(s.accessToken).catch((e: Error) => setError(e.message));
  }, []);

  async function createOrg() {
    const s = loadSession();
    if (!s || !name.trim()) return;
    try {
      await apiFetch("/api/v1/organizations", {
        method: "POST",
        token: s.accessToken,
        body: JSON.stringify({ name, is_personal: false }),
      });
      setName("");
      await reload(s.accessToken);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Error");
    }
  }

  return (
    <section>
      <h1 className="hero-title">Organizaciones</h1>
      <div className="panel stack">
        <label>
          Nueva organización
          <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Nombre" />
        </label>
        <button className="btn" type="button" onClick={createOrg}>
          Crear
        </button>
        {error && <p className="error">{error}</p>}
      </div>
      <div className="panel" style={{ marginTop: "1rem" }}>
        <table className="table">
          <thead>
            <tr>
              <th>Nombre</th>
              <th>Slug</th>
              <th>Tipo</th>
              <th>Rol</th>
            </tr>
          </thead>
          <tbody>
            {orgs.map((o) => (
              <tr key={o.id}>
                <td>{o.name}</td>
                <td>{o.slug}</td>
                <td>{o.is_personal ? "Personal" : "Empresa"}</td>
                <td>{o.role}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
