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
- Mantener el `applicationId` actual (`com.example.rol_pagos_app`) hasta que se defina el package final del producto. Si Google Cloud rechaza crear el OAuth Android porque “ya está en uso”, se debe reutilizar el proyecto donde ya existe o cambiar el package a uno propio/único.

### Cambios realizados
- `lib/services/gmail_auth_service.dart`
  - Captura robusta de errores en `tryRestoreSession` y `signIn`.
  - Listener único a `authenticationEvents` con `onError` y cancelación en cada `initialize` para evitar duplicación.
  - `onCurrentUserChanged` filtra errores del stream para que Riverpod no trate el error como no manejado.

### Pruebas realizadas
- `flutter analyze lib/services/gmail_auth_service.dart`: OK.

### Pendientes
- Google Cloud Console:
  - Crear/verificar **OAuth Client ID tipo Android** con:
    - Package: `com.example.rol_pagos_app`
    - SHA-1 (debug): `1F:A2:55:83:72:66:EC:08:9F:5D:FC:6C:5B:86:2C:98:6E:53:7C:ED`
  - Si aparece “nombre del paquete y huella digital ya están en uso”, localizar el proyecto/cuenta donde ya está registrado y trabajar en ese proyecto (mismo Web Client ID / APIs), o cambiar a un package propio y regenerar credenciales.
