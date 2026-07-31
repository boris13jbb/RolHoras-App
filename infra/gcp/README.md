# Infraestructura GCP — Rol Pagos SaaS

## Servicios

| Recurso | Uso |
|---|---|
| Cloud Run `rol-pagos-api` | FastAPI |
| Cloud Run `rol-pagos-worker` | Procesamiento PDF |
| Pub/Sub topic `gmail-push` | Push de Gmail |
| Pub/Sub subscription push → `/api/v1/webhooks/gmail/pubsub` | Entrega autenticada |
| Cloud Scheduler | Renovar `users.watch` diario + reconciliación 6/12h |
| Secret Manager | OAuth client secret, Fernet/KMS keys, service role |
| Cloud Storage bucket privado | PDFs |
| Artifact Registry | Imágenes Docker |

## Pub/Sub

1. Crear topic `gmail-push`.
2. Dar a `gmail-api-push@system.gserviceaccount.com` permiso `roles/pubsub.publisher`.
3. Crear push subscription autenticada (OIDC) hacia la URL pública de la API.
4. Configurar DLQ y reintentos con backoff.

## Scheduler

```text
# Renovación watch (diario)
POST /api/v1/internal/gmail/renew-watches

# Reconciliación
POST /api/v1/internal/gmail/reconcile
```

Los endpoints internos deben protegerse con OIDC de Scheduler (no exponerlos públicos sin auth).

## Despliegue Cloud Run (ejemplo)

```powershell
cd "d:\RolHoras App\services\api"
gcloud builds submit --tag REGION-docker.pkg.dev/PROJECT/rolpagos/api:latest
gcloud run deploy rol-pagos-api --image REGION-docker.pkg.dev/PROJECT/rolpagos/api:latest --region REGION --allow-unauthenticated=false
```

## Checklist de producción

- [ ] OAuth consent screen + verificación `gmail.readonly`
- [ ] Redirect URI de producción
- [ ] Audience JWT Pub/Sub = URL exacta del webhook
- [ ] RLS activo y service-role solo en API/worker
- [ ] Backups Postgres + prueba de restauración
- [ ] Alertas: watch fallido, cola profunda, 5xx
