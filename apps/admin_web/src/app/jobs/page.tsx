"use client";

export default function JobsPage() {
  return (
    <section>
      <h1 className="hero-title">Trabajos</h1>
      <p className="lead">
        Los trabajos de extracción y sincronización se almacenan en <code>processing_jobs</code>.
        El worker Python los reclama con bloqueo optimista y reintentos con backoff.
      </p>
      <div className="panel">
        <p className="muted">
          Estados: pending → running → succeeded | failed → dead. Los fallidos pueden reencolarse
          desde operaciones (endpoint de reintento previsto en fase operativa).
        </p>
      </div>
    </section>
  );
}
