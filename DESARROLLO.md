# DESARROLLO — SaaS Rol de Pagos

## Objetivo general

Convertir el repositorio en un SaaS profesional: Gmail automático en backend, multiempresa, worker PDF, panel web, suscripciones y seguridad.

## Estado actual del sistema

- Monorepo operativo: Flutter + FastAPI + worker + Next.js + Postgres (Docker :5433).
- Migración `001_init_schema.sql` aplicada (23 tablas + RLS).
- Smoke de integración local OK (bootstrap, Gmail authorize URL, aislamiento 403, horas Decimal).

## Archivos creados / modificados (principales)

- `docs/*`, `DESARROLLO.md`, `README.md`, `.gitignore`, `.env.example`, `docker-compose.yml`
- `services/api/**`, `services/worker/**`
- `apps/admin_web/**`
- `supabase/migrations/001_init_schema.sql`
- `infra/gcp/README.md`, `.github/workflows/ci.yml`
- Flutter: `rol_pagos_api_client.dart`, `features/saas/**`, ajustes Settings

## Fases

| Fase | Estado |
|---|---|
| 0 Análisis/docs | Completa |
| 1 Gmail | Completa (falta prueba real con credenciales) |
| 2 Multiempresa | Completa |
| 3 Worker PDF | Completa |
| 4 Horas/reglas | Completa |
| 5 Flutter API | Completa |
| 6 Panel web | Completa |
| 7 Suscripciones | Completa (noop; Kushki requiere comercio) |
| 8 Seguridad/prod | Parcial (CI/health/rate-limit/retención; MFA/OIDC Scheduler endurecer en prod) |

## Pruebas realizadas

- pytest API/worker
- vitest + next build
- flutter test (parser + api client) + analyze
- smoke HTTP contra API+Postgres

## Problemas encontrados

- Puerto 5432 ocupado por otro contenedor → SaaS en **5433**.
- Docker Desktop debía iniciarse manualmente.
- Escritura automática de `.env` con clave Fernet bloqueada por política del entorno → el usuario debe generar la clave localmente.

## Decisiones técnicas

- Conservar `rol_pagos_app` sin mover a `apps/mobile`.
- Fernet local con interfaz preparada para KMS/Secret Manager.
- Gmail OAuth solo en backend; Flutter abre `authorization_url`.
- Carga manual PDF como respaldo (`POST /documents/upload`).

## Pendientes

- Credenciales Google/Supabase/Pagos reales.
- Prueba E2E Gmail con correo real anonimizado.
- Endpoints internos Scheduler con OIDC estricto en producción.
- MFA UI completa para roles privilegiados.

---

## Actualización 2026-07-30 — Deploy cloud (Vercel + Render)

### Objetivo
Eliminar dependencia de `localhost` en el teléfono (`ERR_CONNECTION_REFUSED`).

### Hecho
- Panel admin en Vercel: https://rol-pagos-admin.vercel.app
- API en Render: https://rolpagos-api.onrender.com
- Postgres Prisma provisionada + esquema `001_init_schema.sql` aplicado
- Docs: `docs/DESPLIEGUE_CLOUD.md`
- Flutter: URL SaaS por defecto apunta a la API pública; textos del panel usan Vercel

### Acción humana pendiente
Añadir en Google Cloud (cliente OAuth Web del backend) el redirect:
`https://rolpagos-api.onrender.com/api/v1/integrations/gmail/callback`

---

## Actualización 2026-07-31 — Automático SaaS (remitente + cron)

### Problema
Sync devolvía “Documentos nuevos: 0” porque el filtro de remitente solo estaba en el teléfono, no en el servidor, y no había reconciliación periódica.

### Solución
- Flutter: botón **Activar automático** copia remitente a la API y fuerza sync completa.
- API: `full=true` en sync; al guardar filtros reescanea; `X-Internal-Token` para reconcile.
- Cron Render cada 6 h → `/api/v1/internal/gmail/reconcile`.
- `ENABLE_DEV_BOOTSTRAP=true` para sesión beta en panel cloud.
