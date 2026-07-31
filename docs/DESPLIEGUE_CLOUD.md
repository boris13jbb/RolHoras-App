# Despliegue cloud (sin depender del PC)

## URLs de producción actuales

| Componente | URL |
| --- | --- |
| Panel admin (Vercel) | https://rol-pagos-admin.vercel.app |
| API (Render) | https://rolpagos-api.onrender.com |
| Callback OAuth Gmail | https://rolpagos-api.onrender.com/api/v1/integrations/gmail/callback |

## Por qué fallaba `localhost` en el teléfono

Google redirige al navegador del móvil. `localhost` en el teléfono es el propio dispositivo, no tu PC → `ERR_CONNECTION_REFUSED`.

## Acción humana obligatoria (Google Cloud)

En el cliente OAuth **Web** usado por el backend, añade URI de redirección autorizada:

```text
https://rolpagos-api.onrender.com/api/v1/integrations/gmail/callback
```

Conserva la de local solo si sigues desarrollando en PC:

```text
http://localhost:8000/api/v1/integrations/gmail/callback
```

Orígenes JavaScript autorizados (si aplica):

```text
https://rol-pagos-admin.vercel.app
```

## Panel admin

1. Abrir https://rol-pagos-admin.vercel.app/login
2. Crear sesión bootstrap (correo + nombre + organización)
3. Ir a **Gmail → Conectar Gmail**

## App Flutter (Sesión SaaS)

1. URL API: `https://rolpagos-api.onrender.com`
2. Pegar Access token y Organization ID del bootstrap del panel
3. Guardar y usar Gmail SaaS

## Nota Render free

El plan free puede dormir tras inactividad. La primera petición puede tardar ~30–60 s en “despertar”.
