# DESARROLLO

## Objetivo general de la tarea
Generar una APK de prueba para validar la aplicación Android `RolPagosApp`.

## Estado actual del sistema
- Proyecto Flutter detectado en `rol_pagos_app`.
- Dependencias instaladas correctamente con `flutter pub get`.
- Análisis estático limpio después de corregir un aviso menor.
- APK debug generada correctamente.

## Archivos revisados
- `pubspec.yaml`
- `lib/data/local/app_database.dart`

## Archivos creados, modificados o eliminados
- Creado: `DESARROLLO.md`
- Modificado: `lib/data/local/app_database.dart`

## Fases de desarrollo
1. Análisis del proyecto Flutter.
2. Instalación de dependencias.
3. Validación estática.
4. Limpieza menor de lint.
5. Generación de APK debug.
6. Ejecución de pruebas automáticas.

## Avances realizados
- Se instaló el árbol de dependencias del proyecto.
- Se corrigió el constructor de pruebas de `AppDatabase` usando super parameters.
- Se generó la APK en `build/app/outputs/flutter-apk/app-debug.apk`.
- Se ejecutaron análisis estático y pruebas automáticas.

## Problemas encontrados
- `flutter analyze` reportó inicialmente un aviso `use_super_parameters` en `AppDatabase.forTesting`.

## Decisiones técnicas tomadas
- Se generó una APK debug porque es la opción más directa para instalar y probar rápidamente en un dispositivo Android.
- No se generó APK release porque requeriría revisar configuración de firma antes de usarla como entregable formal.

## Pruebas realizadas
- `flutter pub get`
- `dart format lib/data/local/app_database.dart`
- `flutter analyze`
- `flutter build apk --debug`
- `flutter test`

## Pendientes
- Probar instalación real en un dispositivo Android.
- Validar navegación principal, carga inicial y flujos manuales desde la APK instalada.
- Generar APK release firmada cuando se necesite distribución externa.
- Implementar sincronización Gmail en segundo plano con autenticación robusta (si GoogleSignIn no permite refresh sin UI, se requiere estrategia alternativa).
- Mejorar conciliación PDF vs app con reglas de negocio confirmadas (qué campos del rol se consideran “equivalentes”).

## Estado final de cada fase
- Análisis: completo.
- Dependencias: completo.
- Limpieza: completo.
- Build APK debug: completo.
- Pruebas automáticas: completo.
- Validación manual en dispositivo: pendiente.

---

## Actualización 2026-04-27 — Background + conciliación + CRUD

### Cambios realizados
- UI: se corrigió overflow del selector de porcentaje en Registro.
- Gmail: guardrails cuando falta configuración; UI no falla y explica cómo configurarlo.
- Pagos: editar/eliminar pagos manuales desde Historial.
- Background (Android): integración con WorkManager para programar sync periódico (cada 6h).
- Conciliación: comparación por mes entre valores detectados del PDF y balance de la app, con alerta y detalle.

### Archivos tocados
- `pubspec.yaml` (se agregó `workmanager`)
- `lib/background/background_tasks.dart`
- `lib/main.dart`
- `lib/services/secure_storage_service.dart`
- `lib/services/gmail_auth_service.dart`
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/features/hours/application/manual_hours_controller.dart`
- `lib/features/payroll/presentation/payroll_history_screen.dart`

### Validaciones
- `flutter analyze`: OK
- `flutter test`: OK
- `flutter build apk --debug`: OK (si aparece error de daemon Kotlin incremental, normalmente se resuelve con `flutter clean` y recompilar).

### Revisión cálculo de horas vs contrato
- Añadido: `docs/CALCULO_HORAS_Y_CONTRATO.md` (explicación detallada de fórmulas en código, mapeo a cláusulas del convenio, límites y pendientes de producto).

---

## Actualización 2026-04-28 — Gmail OAuth (Error 28444) + manejo de errores

### Objetivo
Habilitar el inicio de sesión con Gmail (Google Sign-In) sin fallos por configuración faltante en Google Cloud y sin “Unhandled Exception” en runtime.

### Estado actual
- La app compila y corre en Android (debug).
- El flujo de Google Sign-In falla con `GoogleSignInException` **[28444] Developer console is not set up correctly** si Google Cloud no tiene el cliente OAuth Android (package + SHA-1) asociado al proyecto.

### Problemas encontrados
- Error 28444: falta o no coincide la credencial OAuth de tipo **Android** en Google Cloud.
- El plugin `google_sign_in` emite errores por `authenticationEvents` (`addError`) además de relanzar la excepción; si hay listeners sin `onError`, aparece “Unhandled Exception” aunque el `Future` se capture.

### Decisiones técnicas tomadas
- Manejar errores de forma segura en `GmailAuthService` para evitar ruido y mantener UI estable.
- `applicationId`/`namespace` Android definidos como **`com.rolhoras.rol_pagos_app`** para evitar choques con otros proyectos OAuth (par package + SHA-1 ya usado en otra app/proyecto).

### Cambios realizados
- Android: `applicationId`/`namespace` → `com.rolhoras.rol_pagos_app`; `MainActivity.kt` movido al paquete nuevo.
- `lib/services/gmail_auth_service.dart`
  - Captura robusta de errores en `tryRestoreSession` y `signIn`.
  - Listener único a `authenticationEvents` con `onError` y cancelación en cada `initialize` para evitar duplicación.
  - `onCurrentUserChanged` filtra errores del stream para que Riverpod no trate el error como no manejado.

### Pruebas realizadas
- `flutter analyze lib/services/gmail_auth_service.dart`: OK.

### Pendientes
- Google Cloud Console:
  - Crear/verificar **OAuth Client ID tipo Android** con:
    - Package: `com.rolhoras.rol_pagos_app`
    - SHA-1 (debug): `1F:A2:55:83:72:66:EC:08:9F:5D:FC:6C:5B:86:2C:98:6E:53:7C:ED`
  - Si aparece “nombre del paquete y huella digital ya están en uso”, localizar el proyecto/cuenta donde ya está registrado y trabajar en ese proyecto (mismo Web Client ID / APIs), o cambiar a un package propio y regenerar credenciales.

---

## Actualización 2026-04-29 — Historial: ver/eliminar PDFs importados

### Objetivo
Permitir al usuario **ver** y **eliminar** los PDFs importados desde la pantalla de Historial.

### Análisis realizado
- Pantalla: `lib/features/payroll/presentation/payroll_history_screen.dart` lista roles importados pero no ofrecía acciones.
- Datos: `PayrollDocument.localPath` existe (guardado en DB al importar).

### Cambios realizados
- UI Historial: se añadió menú por cada PDF con acciones:
  - **Ver PDF** (abre visor externo del dispositivo).
  - **Procesar** (reusa la acción existente).
  - **Eliminar** (con confirmación).
- Persistencia:
  - `PayrollDocumentsDao.deleteById`
  - `PayrollRepository.deletePayroll` (borra archivo local + registro en DB)
- Dependencias:
  - `open_filex` para abrir el PDF con app del sistema.

### Validaciones realizadas
- `flutter analyze`: OK.

---

## Actualización 2026-04-29 — Gmail Sync: filtrar solo roles del remitente

### Problema detectado
El sincronizador estaba trayendo PDFs que no correspondían a roles de pago cuando el remitente no estaba configurado correctamente o el query era muy amplio.

### Causa
El query `has:attachment filename:pdf` puede coincidir con cualquier PDF en Gmail; además, el usuario podía dejar el remitente vacío o ingresar un correo que no era el del emisor del rol.

### Solución aplicada
- Se requiere un **remitente** explícito para sincronizar.
- Se filtró por Gmail usando únicamente `from:<remitente> has:attachment filename:pdf` para traer **solo PDFs del remitente**, sin heurísticas por asunto/nombre (en empresas suelen ser nombres numéricos).
- Se ajustó la UI para que el campo deje claro que debe ser el **correo que envía el rol** (ej. RRHH/Nómina).

### Validación realizada
- Pendiente de prueba funcional con cuenta Gmail real (depende de tu configuración de Google Cloud y contenido del buzón).

---

## Actualización 2026-04-30 — Gmail Sync: asignar mes/año por fecha del correo

### Problema detectado
Los PDFs importados desde Gmail se guardaban con el **mes/año actual**, lo que desordena el historial y la conciliación cuando el rol corresponde a otro periodo.

### Causa
`GmailSyncService` usaba `DateTime.now()` para `year/month` al importar adjuntos.

### Solución aplicada
- Se calcula `messageDate` por correo usando `Message.internalDate` (timestamp confiable de Gmail).
- Se usa `messageDate.year/month` al llamar a `importGmailPdf`.
- Fallback: si no hay `internalDate`, se intenta parsear el header `Date`; si falla, se usa `DateTime.now()`.

### Validación realizada
- `flutter analyze`: OK.

---

## Actualización 2026-04-30 — Periodo exacto: detectar mes/año desde el PDF

### Requisito
Los roles llegan “corridos” (ej. rol de **enero** llega en **febrero**), por lo que la fecha del correo no refleja el periodo real.

### Solución aplicada
- Se extendió `PayrollPdfTextParser` para detectar **mes/año** dentro del texto del PDF (patrones tipo “mes de Marzo del año 2026” o “marzo 2026”).
- Se añadió detección robusta por **rango de fechas** del rol (ej. “Del: 1/3/2026 al 31/3/2026”), que es el formato real observado en tus roles.
- Al **procesar** un rol (`PayrollRepository.processPayroll`), si el parser detecta periodo, se actualiza `year/month` del registro.

### Validación realizada
- Pendiente con PDFs reales (necesita que el texto extraído contenga el mes/año).

---

## Actualización 2026-04-30 — Alineación de documentación: expediente técnico

### Objetivo
Mantener `expediente_tecnico.md` alineado con el estado real del repositorio para evitar contradicciones.

### Cambios realizados
- Se agregó al inicio de `expediente_tecnico.md` un bloque **“Estado actual del sistema (2026-04-30)”** con:
  - features implementadas (Historial, Gmail sync, background, periodo exacto por PDF),
  - `applicationId` actual (`com.rolhoras.rol_pagos_app`),
  - referencias a `DESARROLLO.md`.
- Se corrigió el ejemplo de remitente esperado y notas de configuración.
- Se alinearon secciones internas del expediente para que reflejen el repo actual:
  - Dependencias y versiones (según `pubspec.yaml`).
  - Estructura de carpetas (según `lib/` actual).
  - Queries de Gmail (sin `newer_than`, con remitente configurable).
  - Dependencias futuras marcadas explícitamente como “futuro” (notificaciones/biometría/OCR).

---

## Actualización 2026-04-30 — Gmail Sync: auto-procesar PDFs importados (opción 1)

### Objetivo
Que al sincronizar desde Gmail, los roles importados se **procesen automáticamente** usando la contraseña del PDF guardada.

### Solución aplicada
- `GmailSyncService.syncPayrollPdfs` ahora acepta `pdfPassword`:
  - si hay contraseña: importa y luego llama a `PayrollRepository.processPayroll`.
  - si no hay contraseña: marca el rol como `pendingPassword` y deja una nota.
- `GmailSyncResult` ahora reporta: `imported`, `processed`, `pendingPassword`, `duplicates`, `failed`.
- UI: mensaje de sincronización en Ajustes muestra el desglose (importados/procesados/pendientes/duplicados/fallidos).
- Background: el resultado de WorkManager también guarda el desglose anterior.

### Validación realizada
- `flutter analyze`: OK.
