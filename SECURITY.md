# Seguridad del repositorio

Este repositorio procesa documentos de rol de pagos y credenciales de integraciones. Por ese motivo, secretos, documentos reales y escaneos personales **no deben versionarse**.

## Reglas obligatorias

- Guardar secretos únicamente en variables de entorno o gestores de secretos (Render, GitHub Actions, GCP Secret Manager, etc.).
- No subir archivos `client_secret*.json`, service accounts, claves privadas, `.env`, keystores ni credenciales OAuth.
- No subir roles de pago, PDFs desbloqueados, capturas de documentos personales, contratos escaneados ni ZIP de respaldo.
- Para pruebas, usar fixtures sintéticos/anónimos dentro de los tests de código.
- `ENABLE_DEV_BOOTSTRAP` debe permanecer deshabilitado en producción.
- `SCHEDULER_SECRET` debe ser exclusivo, aleatorio y distinto del secreto JWT.

## Si un secreto fue publicado

Eliminarlo del último commit **no lo invalida ni lo borra del historial**. Se debe:

1. Revocar o rotar inmediatamente la credencial en el proveedor correspondiente.
2. Actualizar el secreto en Render/GitHub/GCP sin incluirlo en Git.
3. Eliminar el archivo del árbol actual.
4. Purgar el historial con `git filter-repo` o BFG y hacer force-push coordinado si el repositorio ya fue público.
5. Revisar logs y accesos posteriores a la exposición.

## Incidente detectado durante el hardening

Se detectaron en el historial del repositorio un archivo de credenciales OAuth de Google y varios documentos/escaneos usados durante pruebas. El árbol actual se limpia en la rama de hardening, pero las credenciales expuestas deben considerarse comprometidas hasta ser rotadas y el historial debe purgarse antes de declarar el repositorio saneado.

## Producción

Antes de desplegar una versión productiva, verificar como mínimo: secretos rotados, OAuth callback HTTPS, CORS restringido, bootstrap de desarrollo deshabilitado, token de scheduler independiente, cifrado de tokens con clave no predeterminada, MFA para roles privilegiados y pruebas E2E con datos anonimizados.
