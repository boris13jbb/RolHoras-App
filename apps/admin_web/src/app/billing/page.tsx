"use client";

import { useEffect, useState } from "react";
import { apiFetch, loadSession } from "@/lib/api";

type Plan = { code: string; name: string; max_employees?: number; features: Record<string, boolean> };

export default function BillingPage() {
  const [plans, setPlans] = useState<Plan[]>([]);
  const [sub, setSub] = useState<Record<string, unknown> | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    apiFetch<Plan[]>("/api/v1/billing/plans")
      .then(setPlans)
      .catch((e: Error) => setError(e.message));
    const s = loadSession();
    if (!s) return;
    apiFetch<Record<string, unknown>>(`/api/v1/billing/subscription?organization_id=${s.organizationId}`, {
      token: s.accessToken,
    })
      .then(setSub)
      .catch(() => undefined);
  }, []);

  return (
    <section>
      <h1 className="hero-title">Planes y suscripciones</h1>
      {error && <p className="error">{error}</p>}
      {sub && (
        <div className="panel" style={{ marginBottom: "1rem" }}>
          <p>
            Suscripción actual: <strong>{String(sub.status)}</strong> · plan{" "}
            <strong>{String(sub.plan_code || "—")}</strong>
          </p>
        </div>
      )}
      <div className="grid">
        {plans.map((p) => (
          <div className="metric" key={p.code}>
            <span className="muted">{p.code}</span>
            <strong>{p.name}</strong>
            <p className="muted">Hasta {p.max_employees ?? "∞"} empleados</p>
          </div>
        ))}
      </div>
    </section>
  );
}
