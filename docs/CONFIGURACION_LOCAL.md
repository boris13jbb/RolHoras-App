# Guía de configuración local y bloqueos humanos

## 1. Variables de entorno

```powershell
cd "d:\RolHoras App"
Copy-Item .env.example .env
# Editar .env y generar clave Fernet:
.\.venv\Scripts\python.exe -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
# Pegar el valor en TOKEN_ENCRYPTION_KEY=
```

Completar también (cuando los tengas):

- `GOOGLE_OAUTH_CLIENT_ID`
- `GOOGLE_OAUTH_CLIENT_SECRET`
- `GOOGLE_OAUTH_REDIRECT_URI`
- `GMAIL_PUBSUB_TOPIC`
- `GMAIL_PUBSUB_AUDIENCE`
- `SUPABASE_URL` / `SUPABASE_JWT_SECRET` (o mantener secret local de desarrollo)

## 2. Postgres

```powershell
# Arrancar Docker Desktop primero, luego:
cd "d:\RolHoras App"
docker compose up -d postgres
# Postgres del SaaS escucha en localhost:5433 (5432 suele estar ocupado).
```

La migración `supabase/migrations/001_init_schema.sql` se aplica al inicializar el volumen.

## 3. API y worker

```powershell
cd "d:\RolHoras App"
.\.venv\Scripts\Activate.ps1
cd services\api
uvicorn app.main:app --reload --port 8000

# Otra terminal:
cd "d:\RolHoras App\services\worker"
..\..\.venv\Scripts\python.exe -m app.main
```

## 4. Panel admin

```powershell
cd "d:\RolHoras App\apps\admin_web"
npm install
npm run dev
```

Abrir http://localhost:3000 → Sesión → crear bootstrap de desarrollo.

## 5. Prueba real Gmail → PDF (acción humana)

1. Crear OAuth Client tipo Web en Google Cloud.
2. Añadir redirect `http://localhost:8000/api/v1/integrations/gmail/callback`.
3. Habilitar Gmail API.
4. Crear topic Pub/Sub y conceder publish a Gmail.
5. Poner client id/secret y topic en `.env`.
6. Desde el panel: Conectar Gmail → autorizar.
7. Enviar un correo de prueba con PDF desde el remitente filtrado.
8. Verificar documento en `/documents` y job en worker **con la app cerrada**.

## 6. Seguridad

- No subir `.env`, `client_secret*.json`, PDFs reales ni service-role keys.
- Rotar cualquier secreto que haya estado en el árbol del repo.

## 7. Android · Gmail local (opcional; no requerido para SaaS)

Proyecto Firebase correcto: **`rol-pagos-saas-b7b04`**.

| Campo | Valor |
| --- | --- |
| Package | `com.rolhoras.rol_pagos_app` |
| SHA-1 debug | `FA:BA:45:3F:E3:71:8A:26:10:4B:3B:A7:7F:96:7E:10:4D:6C:B2:51` |
| Web Client ID (pegar en Ajustes) | `398451651219-6lblq3morscifre6ka35jmtk01db4k0l.apps.googleusercontent.com` |

Estado actual (2026-07-30):

1. SHA-1 debug registrado en la app Android de Firebase.
2. Acceso con Google habilitado en Firebase Authentication.
3. `google-services.json` incluye `oauth_client` Android (type 1) + Web (type 3).

Pasos en el teléfono:

1. Reinstala o haz hot restart de la app (`flutter run` de nuevo tras cambiar el JSON).
2. En **Ajustes → Gmail local → OAuth**, pega el **Web Client ID** de la tabla (sin `https://`).
3. Pulsa **Conectar Gmail**.

Si vuelve `Account reauth failed` / `[16]`: el Client ID pegado es de otro proyecto (p. ej. prefijo distinto de `398451651219`). Usa el de la tabla.

Alternativa recomendada para producción: **Gmail SaaS** o el panel **https://rol-pagos-admin.vercel.app/gmail** (ver `docs/DESPLIEGUE_CLOUD.md`).

