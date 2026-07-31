"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { apiFetch, saveSession } from "@/lib/api";

type BootstrapResponse = {
  access_token: string;
  user_id: string;
  organization_id: string;
  email: string;
};

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("admin@example.com");
  const [fullName, setFullName] = useState("Admin Demo");
  const [orgName, setOrgName] = useState("Empresa Demo");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const data = await apiFetch<BootstrapResponse>("/api/v1/dev/bootstrap", {
        method: "POST",
        body: JSON.stringify({
          email,
          full_name: fullName,
          organization_name: orgName,
        }),
      });
      saveSession({
        accessToken: data.access_token,
        organizationId: data.organization_id,
        email: data.email,
        userId: data.user_id,
      });
      router.push("/");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error de sesión");
    } finally {
      setLoading(false);
    }
  }

  return (
    <section className="panel" style={{ maxWidth: 480 }}>
      <h1 className="hero-title" style={{ fontSize: "1.8rem" }}>
        Sesión de desarrollo
      </h1>
      <p className="lead">
        En producción se usa Supabase Auth. Este formulario solo genera un JWT local para pruebas.
      </p>
      <form className="stack" onSubmit={onSubmit}>
        <label>
          Correo
          <input value={email} onChange={(e) => setEmail(e.target.value)} type="email" required />
        </label>
        <label>
          Nombre
          <input value={fullName} onChange={(e) => setFullName(e.target.value)} required />
        </label>
        <label>
          Organización
          <input value={orgName} onChange={(e) => setOrgName(e.target.value)} required />
        </label>
        {error && <p className="error">{error}</p>}
        <button className="btn" disabled={loading} type="submit">
          {loading ? "Creando…" : "Entrar"}
        </button>
      </form>
    </section>
  );
}
