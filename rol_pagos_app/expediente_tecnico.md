# EXPEDIENTE TÉCNICO CONSOLIDADO COMPLETO
# Aplicación RolHoras – Rol de pago PDF, control de horas, pagos, deudas, dashboard y comparación con PDF

**Documento consolidado:** Sí  
**Archivos integrados:**  
1. `documento.md`  
2. `expediente_tecnico_rolhoras.md`  

**Objetivo de este archivo:** Unificar en un solo documento Markdown todo el contenido de los dos documentos proporcionados, conservando la información técnica, funcional, arquitectónica, reglas de negocio, cálculos, pantallas, seguridad, fases de desarrollo, criterios de aceptación y anexos.

---

# ESTADO ACTUAL DEL SISTEMA (alineado al repo) — 2026-04-30

Este expediente fue consolidado a partir de documentos iniciales. A continuación se deja un resumen **alineado al código actual del repositorio** (Flutter), para evitar contradicciones con el contenido histórico del documento.

## Implementado (confirmado en código)
- **Importación local de PDF** (File Picker) y registro en historial.
- **Procesamiento de PDF con contraseña**: extracción de texto y parsing de:
  - horas saldo anterior / adeudadas,
  - horas compensadas / pagadas,
  - saldo actual (pendiente o a favor).
- **Periodo exacto por PDF**: al procesar, se detecta el periodo por texto del rol, con prioridad por rango:
  - formato observado: **“Del: d/m/yyyy al d/m/yyyy”** (ej. “Del: 1/3/2026 al 31/3/2026”),
  - fallback por nombre de mes (“marzo 2026”, “mes de marzo del año 2026”).
- **Historial (UX)**: acciones por rol importado:
  - **Ver PDF** (abre visor externo del dispositivo),
  - **Procesar**,
  - **Eliminar** (borra archivo local + registro).
- **Gmail (OAuth)**:
  - Google Sign-In con `gmail.readonly`.
  - Configurable: **OAuth Web Client ID** y **correo del remitente**.
  - Sincronización trae **solo PDFs del remitente**: query `from:<remitente> has:attachment filename:pdf`.
- **Background Android (WorkManager)**:
  - ejecución periódica (cada ~6h) cuando el usuario lo habilita,
  - guardrails: si no hay sesión OAuth restaurable sin UI, el background se **omite** y reporta mensaje (no rompe la app).

## Datos técnicos actuales (Android)
- **Package / applicationId**: `com.rolhoras.rol_pagos_app`
- **APK debug**: se genera en `build/app/outputs/flutter-apk/app-debug.apk`
- **Expediente de desarrollo (tracking)**: ver `DESARROLLO.md`

## Notas importantes (para evitar inconsistencias)
- El documento original menciona remitentes/cuentas de ejemplo. En la app actual el **remitente es configurable** y debe ser el **correo que envía el rol** (p. ej. RRHH/Nómina).
- La sincronización en background está sujeta a limitaciones de Android; no se garantiza “tiempo real”.

---

# PARTE I  
# Expediente técnico profesional original

# Expediente técnico profesional  
## Aplicación Android en Flutter para lectura de rol de pago PDF, control de saldo de horas y dashboard mensual

**Proyecto:** Aplicación de Rol de Pagos  
**Plataforma inicial:** Android  
**Framework:** Flutter  
**Enfoque:** Aplicación móvil segura, mantenible y escalable  
**Nivel del documento:** Técnico, funcional y arquitectónico  
**Versión:** 1.0  

---

## 1. Resumen ejecutivo

Se propone desarrollar una aplicación móvil Android hecha en Flutter que permita al usuario gestionar de forma segura sus roles de pago mensuales recibidos por correo electrónico en formato PDF protegido con contraseña. La aplicación debe conectarse al correo mediante OAuth 2.0, identificar correos enviados por un remitente específico, descargar el PDF adjunto, desbloquearlo con una contraseña proporcionada por el usuario, extraer información relevante del documento y calcular el estado de las horas adeudadas, pagadas, pendientes o a favor.

El sistema también debe permitir el registro manual de horas pagadas al 100%, 50%, 30% u otros porcentajes configurables. Toda la información debe visualizarse en un dashboard claro, con tarjetas, gráficos, historial mensual y alertas visuales.

La solución recomendada debe priorizar:

- Seguridad de credenciales y documentos.
- No guardar contraseñas de correo en texto plano.
- Uso de OAuth 2.0 para Gmail.
- Almacenamiento local cifrado o protegido.
- Arquitectura limpia en Flutter.
- Procesamiento gradual por fases.
- Modo inicial manual antes de automatizar completamente.
- Posibilidad futura de integrar un backend si la lectura de PDF o la automatización de correo supera las limitaciones de Android.

---

## 2. Contexto del problema

Todos los meses el usuario recibe un correo en su cuenta personal de Gmail. Ese correo proviene de un remitente fijo y contiene como archivo adjunto un PDF de rol de pago. El PDF está protegido con contraseña.

La aplicación debe ayudar a:

1. Detectar el correo mensual.
2. Descargar el PDF adjunto.
3. Abrir el PDF protegido usando una contraseña ingresada por el usuario.
4. Extraer datos relacionados con saldo de horas.
5. Permitir registrar manualmente horas que se van pagando.
6. Calcular el estado actualizado de horas.
7. Mostrar resultados en un dashboard mensual.

### Datos del caso de uso

| Elemento | Valor |
|---|---|
| Cuenta objetivo | `boris13jb@gmail.com` |
| Remitente esperado (ejemplo) | `RecursosHumanos.Nomina@vicunha.com.ec` |
| Tipo de archivo | PDF adjunto protegido con contraseña |
| Frecuencia | Mensual |
| Plataforma inicial | Android |
| Framework solicitado | Flutter |

> Nota: en el código actual, el remitente y el OAuth Web Client ID son configurables desde la app (almacén seguro). Evitar dejar datos sensibles fijos en el repo.

---

## 3. Objetivo general

Diseñar y desarrollar una aplicación Android en Flutter que automatice y facilite la lectura mensual de roles de pago en PDF protegidos con contraseña, permita gestionar saldos de horas y visualice el estado de pago de horas mediante un dashboard claro, seguro y mantenible.

---

## 4. Objetivos específicos

1. Implementar autenticación segura con Google mediante OAuth 2.0.
2. Consultar correos de Gmail de forma controlada y con permisos mínimos.
3. Detectar correos del remitente configurado que contengan PDFs adjuntos.
4. Descargar y almacenar temporalmente los PDFs procesados.
5. Desbloquear PDFs usando una contraseña almacenada de forma segura.
6. Extraer texto del PDF para identificar campos relevantes.
7. Registrar manualmente pagos de horas por fecha, cantidad y porcentaje.
8. Calcular horas adeudadas, pagadas, pendientes y sobretiempo a favor.
9. Presentar la información en un dashboard visual y fácil de entender.
10. Mantener historial mensual de roles de pago y registros manuales.
11. Evitar duplicados cuando llegue el mismo correo o PDF más de una vez.
12. Proteger la privacidad de la información laboral y financiera del usuario.

---

## 5. Alcance funcional

### 5.1 Funcionalidades incluidas

| Módulo | Funcionalidad |
|---|---|
| Configuración inicial | Registrar correo objetivo, remitente permitido, contraseña del PDF y reglas de cálculo. |
| Autenticación Google | Inicio de sesión con Google y autorización de lectura de Gmail. |
| Monitor de correo | Búsqueda de correos del remitente con adjuntos PDF. |
| Descarga de adjuntos | Descarga segura del PDF adjunto desde Gmail API. |
| Procesamiento PDF | Apertura con contraseña y extracción de texto. |
| Parser de rol de pago | Identificación de campos como saldo de horas, horas pendientes o datos equivalentes. |
| Registro manual | Ingreso de horas pagadas con porcentaje y observación. |
| Cálculo de saldo | Cálculo automático de deuda, pagos, pendientes y sobretiempo. |
| Dashboard | Visualización de tarjetas, barras de progreso, estado mensual e histórico. |
| Historial | Consulta de roles procesados y registros por mes. |
| Seguridad | Almacenamiento seguro de contraseña, tokens y datos sensibles. |
| Configuración | Porcentajes, reglas, remitente, contraseña PDF, preferencias visuales. |

### 5.2 Funcionalidades fuera del alcance inicial

Estas funcionalidades pueden planificarse para versiones futuras:

- Sincronización en la nube.
- Multiusuario.
- Panel web administrativo.
- Soporte para otros proveedores de correo distintos de Gmail.
- Reconocimiento OCR avanzado si el PDF es escaneado como imagen.
- Lectura automática en tiempo real sin backend.
- Publicación abierta en Google Play sin proceso de verificación OAuth.

---

## 6. Recomendación técnica principal

La solución debe construirse en dos etapas grandes:

### Etapa 1: Aplicación local primero

La primera versión debe funcionar sin conexión al correo. El usuario selecciona manualmente un PDF desde el teléfono, ingresa la contraseña, la app extrae el texto, permite registrar horas y muestra el dashboard.

Esta etapa permite validar:

- Si el PDF puede leerse correctamente.
- Si el texto extraído contiene el saldo de horas.
- Si las fórmulas de cálculo son correctas.
- Si el dashboard responde a la necesidad real.

### Etapa 2: Automatización con Gmail API

Una vez validado el procesamiento local, se agrega conexión segura con Gmail API para buscar y descargar automáticamente los PDFs enviados por el remitente autorizado.

### Por qué este orden es importante

Si se empieza por Gmail y luego se descubre que el PDF no se puede leer bien, se pierde tiempo en automatización antes de validar el punto más crítico: la extracción de datos del rol de pago.

---

## 7. Decisión entre Gmail API, OAuth, IMAP y backend

### 7.1 Alternativas

| Alternativa | Ventajas | Desventajas | Recomendación |
|---|---|---|---|
| Gmail API + OAuth 2.0 | Seguro, oficial, no requiere contraseña del correo, permite buscar mensajes y descargar adjuntos. | Requiere configuración en Google Cloud y permisos OAuth. | Recomendada. |
| IMAP con usuario/contraseña | Más simple conceptualmente. | Riesgoso, puede requerir contraseña de aplicación, menos recomendado para apps modernas. | No recomendado. |
| Backend propio + Gmail API | Mejor para automatización push, seguridad y escalabilidad. | Mayor complejidad y costo de infraestructura. | Recomendado en fase avanzada. |
| Reenvío manual del PDF a la app | Simple para prototipo. | No es automático. | Útil solo en Fase 1. |

### 7.2 Decisión recomendada

Para una app personal o MVP:

- Usar **Gmail API**.
- Usar **OAuth 2.0**.
- Usar alcance mínimo de lectura: `gmail.readonly`.
- No guardar contraseña del correo.
- Hacer búsquedas periódicas con WorkManager.

Para automatización más profesional:

- Usar backend con Gmail API y Pub/Sub.
- El backend recibe notificaciones de Gmail.
- El móvil solo consulta los resultados procesados.

---

## 8. Limitaciones reales de automatización en Android

Es importante entender que Android limita la ejecución constante en segundo plano para ahorrar batería y proteger la privacidad. Por eso, una app móvil no debe prometer revisar el correo en tiempo real cada segundo.

### 8.1 Lo que sí puede hacer la app móvil

- Revisar correos cuando el usuario abre la app.
- Revisar correos de forma periódica usando WorkManager.
- Ejecutar tareas en segundo plano con restricciones de batería.
- Notificar si encuentra un nuevo rol de pago.

### 8.2 Lo que no conviene prometer en móvil puro

- Revisión instantánea garantizada en tiempo real.
- Descarga inmediata siempre que llegue el correo.
- Procesamiento constante aunque el teléfono esté en ahorro de batería extremo.

### 8.3 Solución profesional para detección casi inmediata

Usar un backend con Gmail Push Notifications:

1. Gmail detecta cambios en el buzón.
2. Gmail envía evento a Google Cloud Pub/Sub.
3. Un backend recibe el evento.
4. El backend procesa o registra el nuevo PDF.
5. La app móvil consulta el backend o recibe una notificación push.

Esta arquitectura es más robusta, pero también más compleja.

---

## 9. Arquitectura recomendada

### 9.1 Tipo de arquitectura

Se recomienda usar **Clean Architecture** con separación por capas:

- Presentation: pantallas, widgets, controladores de estado.
- Application: casos de uso y lógica de orquestación.
- Domain: entidades, reglas de negocio, interfaces de repositorios.
- Data: implementaciones concretas de Gmail, PDF, base de datos y almacenamiento seguro.
- Core: utilidades, errores, constantes, seguridad, configuración.

### 9.2 Gestor de estado recomendado

Se recomienda **Riverpod**.

Razones:

- Es moderno y estable para Flutter.
- Permite inyección de dependencias limpia.
- Facilita pruebas unitarias.
- No depende directamente del árbol de widgets.
- Se integra bien con arquitectura por casos de uso.

Alternativas válidas:

| Opción | Cuándo usarla |
|---|---|
| Provider | App pequeña o desarrollador principiante. |
| Riverpod | Recomendado para este proyecto. |
| Bloc | Muy bueno si se quiere máxima estructura y eventos/estados explícitos. |
| GetX | Rápido, pero menos recomendado para arquitectura limpia estricta. |

---

## 10. Diagrama lógico de módulos

```text
┌────────────────────────────────────────────┐
│                  APP FLUTTER                │
├────────────────────────────────────────────┤
│ Presentation                                │
│ - DashboardScreen                           │
│ - PayrollHistoryScreen                      │
│ - HourPaymentFormScreen                     │
│ - SettingsScreen                            │
│ - GmailSetupScreen                          │
├────────────────────────────────────────────┤
│ Application / Use Cases                     │
│ - SyncPayrollEmailsUseCase                  │
│ - ProcessPayrollPdfUseCase                  │
│ - RegisterHourPaymentUseCase                │
│ - CalculateHourBalanceUseCase               │
│ - GetDashboardSummaryUseCase                │
├────────────────────────────────────────────┤
│ Domain                                      │
│ - PayrollDocument                           │
│ - HourPayment                               │
│ - HourBalance                               │
│ - HourRateRule                              │
│ - UserSettings                              │
├────────────────────────────────────────────┤
│ Data                                        │
│ - GmailApiService                           │
│ - PdfExtractionService                      │
│ - SecureStorageService                      │
│ - DriftDatabase                             │
│ - LocalFileStorage                          │
└────────────────────────────────────────────┘
```

---

## 11. Arquitectura con backend opcional

### 11.1 Versión móvil sin backend

```text
Flutter App
   │
   ├── OAuth Google
   │
   ├── Gmail API
   │      └── Busca correo + descarga PDF
   │
   ├── PDF Service
   │      └── Abre PDF con contraseña + extrae texto
   │
   ├── Drift/SQLite local
   │      └── Guarda documentos, saldos y pagos
   │
   └── Dashboard
          └── Muestra indicadores
```

### 11.2 Versión profesional con backend

```text
Gmail
  │
  └── Push Notification
        │
        ▼
Google Pub/Sub
        │
        ▼
Backend seguro
  │     ├── Consulta Gmail API
  │     ├── Descarga PDF
  │     ├── Procesa PDF
  │     ├── Guarda resultado cifrado
  │     └── Envía notificación push
  │
  ▼
Flutter App
  ├── Consulta resumen
  ├── Registra horas
  └── Muestra dashboard
```

### 11.3 Cuándo usar backend

Conviene usar backend si:

- Se necesita automatización casi en tiempo real.
- El PDF no se puede procesar bien en Flutter.
- Se necesita OCR avanzado.
- Se va a publicar la app para muchos usuarios.
- Se requiere auditoría centralizada.
- Se desea sincronización entre dispositivos.

---

## 12. Librerías recomendadas de Flutter

### 12.1 Dependencias principales

| Necesidad | Librería recomendada | Comentario |
|---|---|---|
| Estado | `flutter_riverpod` | Gestión de estado e inyección de dependencias. |
| Base local relacional | `drift` | SQLite tipado, consultas seguras, ideal para historial. |
| SQLite nativo | `sqlite3_flutter_libs` | Soporte para Drift. |
| Rutas | `go_router` | Navegación clara y mantenible. |
| Almacenamiento seguro | `flutter_secure_storage` | Guardar contraseña PDF, tokens auxiliares o secretos locales. |
| Google Sign-In | `google_sign_in` | Inicio de sesión y autorización de scopes. |
| Google APIs Dart | `googleapis` | Cliente Dart para Gmail API. |
| HTTP autenticado | `extension_google_sign_in_as_googleapis_auth` o cliente personalizado | Permite conectar Google Sign-In con Google APIs. |
| Selección de archivos | `file_picker` | Para Fase 1 con PDF manual. |
| Rutas de almacenamiento | `path_provider` | Directorios internos de la app. |
| Criptografía/hash | `crypto` | Hash SHA-256 para evitar duplicados. |
| Gráficos | `fl_chart` | Barras, progreso e histórico mensual. |
| Internacionalización/fechas | `intl` | Fechas, meses y formatos en español. |
| Jobs en Android | `workmanager` | Revisión periódica (con guardrails). |
| PDF extracción | `syncfusion_flutter_pdf` | Extracción de texto de PDFs protegidos. |
| Abrir PDF (visor externo) | `open_filex` | Abrir el archivo con apps del sistema. |
| Notificaciones (futuro) | `flutter_local_notifications` | No implementado aún en este repo. |
| OCR (futuro) | `google_mlkit_text_recognition` | No implementado aún en este repo. |
| Biometría (futuro) | `local_auth` | No implementado aún en este repo. |

### 12.2 Dependencias sugeridas en `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter

  crypto: ^3.0.7
  drift: ^2.32.1
  file_picker: ^11.0.2
  fl_chart: ^1.2.0
  flutter_riverpod: ^3.3.1
  flutter_secure_storage: ^10.0.0
  google_sign_in: ^7.2.0
  googleapis: ^13.2.0
  go_router: ^17.2.2
  http: ^1.5.0
  intl: ^0.20.2
  open_filex: ^4.7.0
  path: ^1.9.1
  path_provider: ^2.1.5
  sqlite3_flutter_libs: ^0.6.0+eol
  syncfusion_flutter_pdf: ^33.2.3
  workmanager: ^0.7.0

# En producción, verificar versiones actuales antes de instalar.
```

---

## 13. Estructura recomendada de carpetas

```text
lib/
│
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   └── app_routes.dart
│   ├── providers/
│   │   ├── app_database_provider.dart
│   │   └── secure_storage_provider.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       ├── crash_logger.dart
│       └── year_month.dart
│
├── data/
│   ├── local/
│   │   ├── app_database.dart
│   │   ├── tables/
│   │   │   ├── payroll_documents_table.dart
│   │   │   ├── hour_payments_table.dart
│   │   │   ├── hour_balances_table.dart
│   │   │   └── user_settings_table.dart
│   │   └── daos/
│   │       ├── payroll_documents_dao.dart
│   │       ├── hour_payments_dao.dart
│   │       ├── hour_balances_dao.dart
│   │       └── user_settings_dao.dart
│
├── services/
│   ├── gmail_auth_service.dart
│   ├── gmail_api_service.dart
│   ├── gmail_config_resolver.dart
│   ├── gmail_sync_service.dart
│   ├── hash_service.dart
│   ├── local_file_service.dart
│   └── secure_storage_service.dart
│
├── shared/
│   ├── layouts/
│   │   └── app_scaffold.dart
│   └── widgets/
│       └── section_card.dart
│
└── background/
    └── background_tasks.dart

features/
├── dashboard/
├── gmail/
├── hours/
├── payroll/
├── pdf_reader/
└── settings/
```

---

## 14. Modelo de datos conceptual

### 14.1 Entidad `PayrollDocument`

Representa un PDF de rol de pago detectado, descargado y procesado.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | String/UUID | Identificador local. |
| `gmailMessageId` | String | ID del mensaje en Gmail. |
| `gmailAttachmentId` | String | ID del adjunto en Gmail. |
| `senderEmail` | String | Remitente. |
| `receivedAt` | DateTime | Fecha de recepción del correo. |
| `periodYear` | int | Año del rol. |
| `periodMonth` | int | Mes del rol. |
| `fileName` | String | Nombre del PDF. |
| `localPath` | String? | Ruta local del archivo si se almacena. |
| `sha256Hash` | String | Hash para evitar duplicados. |
| `isPasswordProtected` | bool | Indica si requiere contraseña. |
| `extractionStatus` | enum | `pending`, `success`, `failed`, `needs_review`. |
| `rawExtractedText` | String? | Texto extraído, idealmente cifrado o minimizado. |
| `detectedInitialDebtHours` | double? | Horas adeudadas detectadas. |
| `detectedPaidHours` | double? | Horas pagadas detectadas, si existe. |
| `detectedPendingHours` | double? | Horas pendientes detectadas, si existe. |
| `createdAt` | DateTime | Fecha de creación local. |
| `updatedAt` | DateTime | Fecha de actualización. |

### 14.2 Entidad `HourPayment`

Representa una entrada manual de horas pagadas o compensadas.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | String/UUID | Identificador local. |
| `payrollDocumentId` | String? | Relación opcional con un rol mensual. |
| `periodYear` | int | Año al que aplica. |
| `periodMonth` | int | Mes al que aplica. |
| `paymentDate` | DateTime | Fecha en que se pagaron/compensaron las horas. |
| `rawHours` | double | Cantidad de horas ingresadas por el usuario. |
| `ratePercent` | double | Porcentaje: 100, 50, 30 u otro. |
| `impactFactor` | double | Factor de impacto configurable. |
| `effectiveHours` | double | Horas efectivas calculadas. |
| `observation` | String? | Observación opcional. |
| `createdAt` | DateTime | Fecha de registro. |
| `updatedAt` | DateTime | Fecha de edición. |

### 14.3 Entidad `HourBalance`

Representa el resumen de un mes.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | String/UUID | Identificador local. |
| `periodYear` | int | Año. |
| `periodMonth` | int | Mes. |
| `initialDebtHours` | double | Horas adeudadas detectadas o ingresadas. |
| `manualAdjustmentHours` | double | Ajuste manual positivo o negativo. |
| `totalEffectivePaidHours` | double | Total de horas efectivas pagadas. |
| `pendingHours` | double | Horas pendientes. |
| `favorHours` | double | Horas a favor si se pagó de más. |
| `status` | enum | `debt`, `paid`, `favor`, `review`. |
| `source` | enum | `pdf`, `manual`, `mixed`. |
| `lastCalculatedAt` | DateTime | Último cálculo. |

### 14.4 Entidad `HourRateRule`

Permite configurar porcentajes y fórmulas.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | String/UUID | Identificador. |
| `name` | String | Nombre: 100%, 50%, 30%, personalizado. |
| `ratePercent` | double | Porcentaje visible. |
| `impactFactor` | double | Factor real usado en cálculo. |
| `description` | String? | Explicación de la regla. |
| `isDefault` | bool | Si viene por defecto. |
| `isActive` | bool | Si está disponible. |

### 14.5 Entidad `UserSettings`

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | String | Identificador único. |
| `gmailAccount` | String? | Cuenta autorizada. |
| `allowedSender` | String | Remitente autorizado. |
| `pdfPasswordSaved` | bool | Indica si existe contraseña en almacenamiento seguro. |
| `autoSyncEnabled` | bool | Activa revisión periódica. |
| `syncIntervalMinutes` | int | Intervalo sugerido. |
| `deletePdfAfterProcessing` | bool | Elimina PDF tras extraer datos. |
| `requireBiometricUnlock` | bool | Solicita huella/rostro al abrir app. |
| `backupEnabled` | bool | Copia de seguridad activada o no. |
| `createdAt` | DateTime | Fecha de creación. |
| `updatedAt` | DateTime | Fecha de actualización. |

---

## 15. Modelo de cálculo de horas

### 15.1 Problema de interpretación

La expresión “horas al 100%, 50% o 30%” puede tener dos interpretaciones según la empresa:

1. **Factor de pago de deuda:** una hora al 50% descuenta 0.5 horas de la deuda.
2. **Factor de recargo laboral:** una hora al 50% puede equivaler a 1.5 horas si se interpreta como recargo de sobretiempo.

Por eso la app no debe quemar una fórmula fija. Debe permitir configurar reglas.

### 15.2 Fórmula base recomendada

```text
horas_efectivas = horas_ingresadas * factor_impacto
```

```text
horas_pendientes = horas_adeudadas - total_horas_efectivas_pagadas
```

```text
si horas_pendientes > 0  → todavía debo horas
si horas_pendientes = 0  → deuda pagada
si horas_pendientes < 0  → tengo horas a favor
```

```text
horas_a_favor = max(0, total_horas_efectivas_pagadas - horas_adeudadas)
```

### 15.3 Tabla de reglas iniciales

| Tipo visible | Factor conservador inicial | Ejemplo con 10 horas | Resultado efectivo |
|---|---:|---:|---:|
| 100% | 1.00 | 10 | 10.00 horas |
| 50% | 0.50 | 10 | 5.00 horas |
| 30% | 0.30 | 10 | 3.00 horas |
| Personalizado | Configurable | 10 | Según regla |

### 15.4 Ejemplo práctico

Supongamos:

- Horas adeudadas iniciales: 40 horas.
- Registro 1: 10 horas al 100% → 10 × 1.00 = 10 horas efectivas.
- Registro 2: 8 horas al 50% → 8 × 0.50 = 4 horas efectivas.
- Registro 3: 5 horas al 30% → 5 × 0.30 = 1.5 horas efectivas.

```text
total_pagado_efectivo = 10 + 4 + 1.5 = 15.5
pendiente = 40 - 15.5 = 24.5
```

Resultado:

- Debe todavía: 24.5 horas.
- No tiene sobretiempo a favor.

### 15.5 Ejemplo con horas a favor

Supongamos:

- Horas adeudadas iniciales: 20 horas.
- Total pagado efectivo: 25 horas.

```text
pendiente = 20 - 25 = -5
horas_a_favor = 5
```

Resultado:

- Deuda terminada.
- Tiene 5 horas a favor.

---

## 16. Flujo de procesamiento del PDF

### 16.1 Flujo normal

```text
1. Usuario autoriza Gmail.
2. App busca correo del remitente configurado.
3. App identifica adjunto PDF.
4. App descarga PDF en memoria o almacenamiento interno.
5. App solicita/recupera contraseña segura del PDF.
6. App intenta abrir PDF.
7. App extrae texto.
8. App aplica reglas de búsqueda/regex.
9. App detecta saldo de horas.
10. App guarda documento y resumen mensual.
11. Dashboard se actualiza.
```

### 16.2 Flujo si falla la contraseña

```text
1. App intenta abrir PDF.
2. PDF rechaza contraseña.
3. App marca documento como needs_password.
4. App solicita contraseña nueva al usuario.
5. App reintenta procesamiento.
6. Si funciona, actualiza almacenamiento seguro.
```

### 16.3 Flujo si no se puede extraer texto

```text
1. App abre PDF.
2. Extracción de texto retorna vacío o incompleto.
3. App marca documento como needs_review.
4. App muestra pantalla para ingreso manual del saldo.
5. Opcional: usar OCR en versión futura.
```

---

## 17. Extracción de información del PDF

### 17.1 Estrategia principal

La app debe extraer texto y aplicar patrones de búsqueda.

Ejemplos de posibles campos:

```text
SALDO HORAS: 32.50
HORAS PENDIENTES: 18.00
HORAS PAGADAS: 14.50
BANCO DE HORAS: -5.00
```

Como no se conoce todavía el formato exacto del PDF, el parser debe ser flexible.

### 17.2 Regex sugeridos

```dart
final saldoRegex = RegExp(
  r'(saldo\s*(de)?\s*horas|horas\s*pendientes|banco\s*de\s*horas)\s*[:\-]?\s*(-?\d+(?:[\.,]\d+)?)',
  caseSensitive: false,
);
```

```dart
final pagadasRegex = RegExp(
  r'(horas\s*pagadas|horas\s*compensadas)\s*[:\-]?\s*(\d+(?:[\.,]\d+)?)',
  caseSensitive: false,
);
```

### 17.3 Normalización de números

El PDF puede traer números como:

- `12.50`
- `12,50`
- `1.234,50`
- `1,234.50`

Se debe crear una función de normalización.

```dart
double parseFlexibleNumber(String value) {
  var text = value.trim();

  if (text.contains(',') && text.contains('.')) {
    final lastComma = text.lastIndexOf(',');
    final lastDot = text.lastIndexOf('.');

    if (lastComma > lastDot) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else {
      text = text.replaceAll(',', '');
    }
  } else if (text.contains(',')) {
    text = text.replaceAll(',', '.');
  }

  return double.parse(text);
}
```

### 17.4 Parser con revisión manual

El parser debe retornar un resultado con nivel de confianza.

```dart
enum ExtractionConfidence {
  high,
  medium,
  low,
  failed,
}

class PayrollExtractionResult {
  final double? initialDebtHours;
  final double? paidHours;
  final double? pendingHours;
  final String rawText;
  final ExtractionConfidence confidence;
  final List<String> warnings;

  PayrollExtractionResult({
    required this.initialDebtHours,
    required this.paidHours,
    required this.pendingHours,
    required this.rawText,
    required this.confidence,
    required this.warnings,
  });
}
```

---

## 18. Seguridad y privacidad

### 18.1 Principios obligatorios

1. No guardar la contraseña del correo.
2. No escribir la contraseña del PDF en el código fuente.
3. Usar OAuth 2.0 para Gmail.
4. Usar permisos mínimos.
5. Guardar la contraseña del PDF solo con almacenamiento seguro.
6. Evitar guardar texto completo del PDF si no es necesario.
7. Cifrar o proteger la base local si se almacenan datos sensibles.
8. Permitir borrar todos los datos desde configuración.
9. Bloquear la app con biometría si el usuario lo activa.
10. Informar claramente qué datos se leen y para qué.

### 18.2 Datos sensibles

La app puede manejar:

- Datos laborales.
- Rol de pago.
- Información salarial.
- Información de horas.
- Correo personal.
- Adjuntos protegidos.
- Contraseña del PDF.

Por eso el diseño debe asumir que los datos son confidenciales.

### 18.3 Almacenamiento seguro

Usar `flutter_secure_storage` para:

- Contraseña del PDF.
- Preferencias sensibles.
- Claves locales de cifrado si se implementa cifrado de base.

No usar `SharedPreferences` para contraseñas.

### 18.4 PDFs descargados

Recomendación:

- Descargar en directorio interno de la app.
- No guardar en carpeta pública de Android.
- Calcular hash SHA-256.
- Procesar el PDF.
- Según configuración, eliminar el PDF original tras extraer los datos.
- Si se conserva, protegerlo y no compartirlo con otras apps.

### 18.5 OAuth y Gmail

Recomendaciones:

- Usar scope de solo lectura.
- Mostrar al usuario una pantalla explicando el permiso.
- No solicitar permisos de envío ni eliminación de correos.
- No modificar correos.
- No guardar tokens manualmente si la librería ya los gestiona.
- Permitir cerrar sesión y revocar acceso.

### 18.6 Riesgos legales y laborales

Antes de automatizar el acceso al correo y procesamiento de roles de pago, el usuario debe considerar:

- Si el correo es personal o corporativo.
- Si la empresa permite procesar documentos laborales en apps personales.
- Si los PDFs contienen información confidencial.
- Si se hará copia o respaldo en la nube.
- Si el dispositivo es compartido.

La app debe ser de uso personal, transparente y segura. Si se va a distribuir a otros empleados, se debe revisar política de privacidad, consentimiento, términos de uso y requisitos legales aplicables.

---

## 19. Base de datos local

### 19.1 Recomendación

Usar **Drift sobre SQLite**.

Razones:

- Los datos son relacionales.
- Hay documentos, pagos, reglas, saldos e historial.
- Permite consultas complejas.
- Es más mantenible que guardar todo como JSON.
- Facilita migraciones.
- Funciona bien offline.

### 19.2 Tablas principales

```text
payroll_documents
hour_payments
hour_balances
hour_rate_rules
user_settings
audit_logs
```

### 19.3 Prevención de duplicados

Debe aplicarse una estrategia combinada:

1. `gmailMessageId` único.
2. `gmailAttachmentId` único.
3. `sha256Hash` del PDF único.
4. `periodYear + periodMonth` controlado.
5. Si llega un PDF nuevo del mismo mes, preguntar si reemplazar, comparar o conservar versión.

### 19.4 Estados de documento

| Estado | Significado |
|---|---|
| `pending` | Descargado, aún no procesado. |
| `processing` | En extracción. |
| `success` | Procesado correctamente. |
| `needs_password` | Contraseña incorrecta o ausente. |
| `needs_review` | Texto extraído, pero datos no confiables. |
| `failed` | Error técnico. |

---

## 20. Diseño de pantallas

### 20.1 Pantalla de inicio / Onboarding

Debe explicar:

- Qué hace la aplicación.
- Qué datos procesa.
- Que no guarda la contraseña del correo.
- Que necesita permiso de Gmail de solo lectura.
- Que la contraseña del PDF se guarda segura.

Botones:

- `Comenzar configuración`
- `Usar modo manual`

### 20.2 Pantalla de configuración de correo

Campos:

- Cuenta Google autorizada.
- Remitente permitido.
- Botón conectar con Google.
- Botón probar búsqueda.
- Estado de permisos.

Acciones:

- Conectar Gmail.
- Desconectar Gmail.
- Buscar último rol.

### 20.3 Pantalla de contraseña del PDF

Campos:

- Contraseña del PDF.
- Confirmar contraseña.
- Opción mostrar/ocultar.
- Opción guardar de forma segura.
- Botón probar con PDF seleccionado.

Validaciones:

- No permitir contraseña vacía si se procesarán PDFs.
- No registrar contraseña en logs.
- No mostrar contraseña en errores.

### 20.4 Dashboard principal

Debe mostrar:

- Tarjeta de horas adeudadas.
- Tarjeta de horas pagadas efectivas.
- Tarjeta de horas pendientes.
- Tarjeta de horas a favor.
- Barra de progreso de pago.
- Estado visual: `Pendiente`, `Pagado`, `A favor`, `Revisar`.
- Gráfico mensual.
- Botón para registrar horas.
- Botón para sincronizar rol.

### 20.5 Pantalla de registro de horas

Campos:

- Fecha.
- Mes/año al que aplica.
- Cantidad de horas.
- Tipo de porcentaje.
- Factor calculado.
- Observación.

Botones:

- Guardar.
- Cancelar.

Validaciones:

- Horas mayores que cero.
- Porcentaje activo.
- Fecha válida.
- Mes seleccionado.

### 20.6 Pantalla de historial mensual

Debe mostrar lista por mes:

| Mes | Deuda inicial | Pagado | Pendiente | Estado |
|---|---:|---:|---:|---|
| Enero 2026 | 40.00 | 15.50 | 24.50 | Pendiente |
| Febrero 2026 | 20.00 | 25.00 | 0.00 | A favor 5.00 |

### 20.7 Detalle mensual

Debe mostrar:

- Datos detectados del PDF.
- Registros manuales del mes.
- Cálculo completo.
- Botón editar saldo inicial.
- Botón reprocesar PDF.
- Botón exportar resumen.

### 20.8 Configuración de porcentajes

Permite:

- Crear regla.
- Editar factor.
- Desactivar regla.
- Restaurar valores por defecto.

Ejemplo:

| Nombre | Porcentaje visible | Factor impacto | Activo |
|---|---:|---:|---|
| 100% | 100 | 1.00 | Sí |
| 50% | 50 | 0.50 | Sí |
| 30% | 30 | 0.30 | Sí |

### 20.9 Configuración de seguridad

Opciones:

- Activar bloqueo biométrico.
- Cambiar contraseña del PDF.
- Borrar contraseña guardada.
- Eliminar PDFs después de procesar.
- Borrar todos los datos.
- Exportar respaldo local.

---

## 21. Diseño visual recomendado

### 21.1 Estilo

- Diseño limpio y profesional.
- Colores sobrios.
- Tarjetas con bordes redondeados.
- Iconos claros.
- Estados con colores:
  - Rojo/naranja: deuda pendiente.
  - Verde: deuda pagada.
  - Azul: horas a favor.
  - Amarillo: requiere revisión.

### 21.2 Componentes del dashboard

| Componente | Uso |
|---|---|
| SummaryCard | Mostrar deuda, pagado, pendiente y a favor. |
| LinearProgressIndicator | Porcentaje de avance. |
| BarChart | Historial mensual. |
| StatusBadge | Estado actual. |
| FloatingActionButton | Registrar nuevo pago de horas. |

### 21.3 Estados visuales

```text
Pendiente:       Debes 24.50 horas
Pagado:          Has completado el pago de horas
A favor:         Tienes 5.00 horas a favor
Revisar:         El PDF fue leído, pero los datos requieren confirmación
```

---

## 22. Código de ejemplo: entidades de dominio

```dart
class PayrollDocument {
  final String id;
  final String? gmailMessageId;
  final String? gmailAttachmentId;
  final String senderEmail;
  final DateTime receivedAt;
  final int periodYear;
  final int periodMonth;
  final String fileName;
  final String? localPath;
  final String sha256Hash;
  final PayrollExtractionStatus extractionStatus;
  final double? detectedInitialDebtHours;
  final double? detectedPaidHours;
  final double? detectedPendingHours;

  const PayrollDocument({
    required this.id,
    required this.gmailMessageId,
    required this.gmailAttachmentId,
    required this.senderEmail,
    required this.receivedAt,
    required this.periodYear,
    required this.periodMonth,
    required this.fileName,
    required this.localPath,
    required this.sha256Hash,
    required this.extractionStatus,
    required this.detectedInitialDebtHours,
    required this.detectedPaidHours,
    required this.detectedPendingHours,
  });
}

enum PayrollExtractionStatus {
  pending,
  processing,
  success,
  needsPassword,
  needsReview,
  failed,
}
```

```dart
class HourPayment {
  final String id;
  final String? payrollDocumentId;
  final int periodYear;
  final int periodMonth;
  final DateTime paymentDate;
  final double rawHours;
  final double ratePercent;
  final double impactFactor;
  final String? observation;
  final DateTime createdAt;

  const HourPayment({
    required this.id,
    required this.payrollDocumentId,
    required this.periodYear,
    required this.periodMonth,
    required this.paymentDate,
    required this.rawHours,
    required this.ratePercent,
    required this.impactFactor,
    required this.observation,
    required this.createdAt,
  });

  double get effectiveHours => rawHours * impactFactor;
}
```

```dart
class HourBalance {
  final int periodYear;
  final int periodMonth;
  final double initialDebtHours;
  final double totalEffectivePaidHours;
  final double pendingHours;
  final double favorHours;
  final HourBalanceStatus status;

  const HourBalance({
    required this.periodYear,
    required this.periodMonth,
    required this.initialDebtHours,
    required this.totalEffectivePaidHours,
    required this.pendingHours,
    required this.favorHours,
    required this.status,
  });
}

enum HourBalanceStatus {
  debt,
  paid,
  favor,
  review,
}
```

---

## 23. Código de ejemplo: servicio de cálculo

```dart
class HourBalanceCalculator {
  HourBalance calculate({
    required int year,
    required int month,
    required double initialDebtHours,
    required List<HourPayment> payments,
  }) {
    final totalPaid = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.effectiveHours,
    );

    final difference = initialDebtHours - totalPaid;

    final pending = difference > 0 ? difference : 0;
    final favor = difference < 0 ? difference.abs() : 0;

    final status = _resolveStatus(
      pendingHours: pending,
      favorHours: favor,
    );

    return HourBalance(
      periodYear: year,
      periodMonth: month,
      initialDebtHours: initialDebtHours,
      totalEffectivePaidHours: totalPaid,
      pendingHours: pending,
      favorHours: favor,
      status: status,
    );
  }

  HourBalanceStatus _resolveStatus({
    required double pendingHours,
    required double favorHours,
  }) {
    const tolerance = 0.0001;

    if (favorHours > tolerance) {
      return HourBalanceStatus.favor;
    }

    if (pendingHours <= tolerance) {
      return HourBalanceStatus.paid;
    }

    return HourBalanceStatus.debt;
  }
}
```

---

## 24. Código de ejemplo: registro de horas

```dart
class RegisterHourPaymentUseCase {
  final HourPaymentRepository repository;

  RegisterHourPaymentUseCase(this.repository);

  Future<void> execute({
    required int year,
    required int month,
    required DateTime paymentDate,
    required double rawHours,
    required double ratePercent,
    required double impactFactor,
    String? observation,
  }) async {
    if (rawHours <= 0) {
      throw ArgumentError('La cantidad de horas debe ser mayor que cero.');
    }

    if (impactFactor < 0) {
      throw ArgumentError('El factor de impacto no puede ser negativo.');
    }

    final payment = HourPayment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      payrollDocumentId: null,
      periodYear: year,
      periodMonth: month,
      paymentDate: paymentDate,
      rawHours: rawHours,
      ratePercent: ratePercent,
      impactFactor: impactFactor,
      observation: observation,
      createdAt: DateTime.now(),
    );

    await repository.save(payment);
  }
}
```

---

## 25. Código de ejemplo: almacenamiento seguro

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _pdfPasswordKey = 'pdf_password';

  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  Future<void> savePdfPassword(String password) async {
    if (password.trim().isEmpty) {
      throw ArgumentError('La contraseña no puede estar vacía.');
    }

    await _storage.write(
      key: _pdfPasswordKey,
      value: password,
    );
  }

  Future<String?> getPdfPassword() {
    return _storage.read(key: _pdfPasswordKey);
  }

  Future<void> deletePdfPassword() {
    return _storage.delete(key: _pdfPasswordKey);
  }
}
```

---

## 26. Código de ejemplo: autenticación Google y Gmail API

> Este código es una guía base. La configuración real requiere crear un proyecto en Google Cloud Console, configurar OAuth Consent Screen, registrar el SHA-1/SHA-256 de Android y habilitar Gmail API.

```dart
import 'package:google_sign_in/google_sign_in.dart';

class GmailAuthService {
  static const gmailReadonlyScope =
      'https://www.googleapis.com/auth/gmail.readonly';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      gmailReadonlyScope,
    ],
  );

  Future<GoogleSignInAccount?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      return null;
    }
    return account;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<Map<String, String>?> getAuthHeaders() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) {
      return null;
    }

    return account.authHeaders;
  }
}
```

### Consulta recomendada a Gmail (alineada a la implementación actual)

```text
from:<remitente_configurado> has:attachment filename:pdf
```

En una implementación real, el remitente debe venir desde configuración:

```dart
String buildPayrollSearchQuery({required String senderEmail}) {
  return 'from:$senderEmail has:attachment filename:pdf';
}
```

### Servicio conceptual de búsqueda

```dart
class GmailPayrollSearchService {
  Future<List<String>> searchPayrollMessageIds({
    required String senderEmail,
    required Map<String, String> authHeaders,
  }) async {
    final query = buildPayrollSearchQuery(senderEmail: senderEmail);

    // Implementar llamada REST a:
    // GET https://gmail.googleapis.com/gmail/v1/users/me/messages?q=$query
    // Usar authHeaders en la petición.

    // Retornar IDs de mensajes encontrados.
    return [];
  }
}
```

---

## 27. Código de ejemplo: extracción de texto desde PDF

> La extracción de PDF debe validarse con un archivo real. Algunos PDFs protegidos o generados como imagen pueden no devolver texto útil. En ese caso se requiere OCR o backend.

```dart
class PdfExtractionService {
  Future<String> extractTextFromProtectedPdf({
    required String filePath,
    required String password,
  }) async {
    // Ejemplo conceptual.
    // Con syncfusion_flutter_pdf se puede cargar el documento y extraer texto.
    // Verificar sintaxis exacta según versión instalada.

    try {
      // final bytes = File(filePath).readAsBytesSync();
      // final document = PdfDocument(inputBytes: bytes, password: password);
      // final extractor = PdfTextExtractor(document);
      // final text = extractor.extractText();
      // document.dispose();
      // return text;

      throw UnimplementedError('Implementar con librería PDF validada.');
    } catch (error) {
      throw Exception('No se pudo leer el PDF. Verifique la contraseña o el formato.');
    }
  }
}
```

---

## 28. Código de ejemplo: parser de saldo de horas

```dart
class PayrollPdfParser {
  PayrollExtractionResult parse(String rawText) {
    final normalizedText = rawText
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final saldoRegex = RegExp(
      r'(saldo\s*(de)?\s*horas|horas\s*pendientes|banco\s*de\s*horas)\s*[:\-]?\s*(-?\d+(?:[\.,]\d+)?)',
      caseSensitive: false,
    );

    final match = saldoRegex.firstMatch(normalizedText);

    if (match == null) {
      return PayrollExtractionResult(
        initialDebtHours: null,
        paidHours: null,
        pendingHours: null,
        rawText: rawText,
        confidence: ExtractionConfidence.failed,
        warnings: const [
          'No se encontró un campo claro de saldo de horas.',
        ],
      );
    }

    final numberText = match.group(match.groupCount);
    final detectedHours = parseFlexibleNumber(numberText!);

    return PayrollExtractionResult(
      initialDebtHours: detectedHours,
      paidHours: null,
      pendingHours: detectedHours,
      rawText: rawText,
      confidence: ExtractionConfidence.medium,
      warnings: const [
        'Validar manualmente el campo detectado la primera vez.',
      ],
    );
  }
}
```

---

## 29. Código de ejemplo: dashboard básico

```dart
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final HourBalance balance;

  const DashboardScreen({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final progress = balance.initialDebtHours == 0
        ? 1.0
        : (balance.totalEffectivePaidHours / balance.initialDebtHours)
            .clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rol de pago y horas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navegar a formulario de registro de horas.
        },
        icon: const Icon(Icons.add),
        label: const Text('Registrar horas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusHeader(balance: balance),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 24),
          _SummaryGrid(balance: balance),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Ejecutar sincronización manual.
            },
            icon: const Icon(Icons.sync),
            label: const Text('Buscar último rol de pago'),
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final HourBalance balance;

  const _StatusHeader({required this.balance});

  @override
  Widget build(BuildContext context) {
    final message = switch (balance.status) {
      HourBalanceStatus.debt =>
        'Todavía debes ${balance.pendingHours.toStringAsFixed(2)} horas',
      HourBalanceStatus.paid => 'Has completado el pago de tus horas',
      HourBalanceStatus.favor =>
        'Tienes ${balance.favorHours.toStringAsFixed(2)} horas a favor',
      HourBalanceStatus.review => 'Revisa los datos extraídos del PDF',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final HourBalance balance;

  const _SummaryGrid({required this.balance});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _SummaryCard(
          title: 'Adeudadas',
          value: balance.initialDebtHours,
        ),
        _SummaryCard(
          title: 'Pagadas',
          value: balance.totalEffectivePaidHours,
        ),
        _SummaryCard(
          title: 'Pendientes',
          value: balance.pendingHours,
        ),
        _SummaryCard(
          title: 'A favor',
          value: balance.favorHours,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double value;

  const _SummaryCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(
              value.toStringAsFixed(2),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text('horas'),
          ],
        ),
      ),
    );
  }
}
```

---

## 30. Flujo de Gmail API

### 30.1 Configuración en Google Cloud

Pasos generales:

1. Crear proyecto en Google Cloud Console.
2. Habilitar Gmail API.
3. Configurar pantalla de consentimiento OAuth.
4. Definir tipo de usuario:
   - Interno si se usa Google Workspace propio.
   - Externo si es una cuenta Gmail personal.
5. Agregar correo de prueba si la app está en modo testing.
6. Crear credenciales OAuth para Android.
7. Registrar package name de la app.
8. Registrar SHA-1/SHA-256 del certificado de desarrollo.
9. Configurar `google-services.json` si se integra Firebase o Google services.
10. Probar inicio de sesión.

### 30.2 Búsqueda de correos

Consulta base:

```text
from:<remitente_configurado> has:attachment filename:pdf
```

Consulta más estricta si se conoce asunto (opcional / futuro):

```text
from:<remitente_configurado> subject:(rol OR pago) has:attachment filename:pdf
```

### 30.3 Descarga de adjunto

Flujo conceptual:

```text
1. users.messages.list
2. users.messages.get
3. Revisar payload.parts
4. Identificar partes con filename .pdf
5. Obtener attachmentId
6. users.messages.attachments.get
7. Decodificar Base64 URL-safe
8. Guardar bytes en almacenamiento interno
9. Calcular SHA-256
10. Procesar PDF
```

### 30.4 Prevención de correos incorrectos

Validar:

- Remitente exacto.
- Archivo con extensión `.pdf`.
- Tamaño razonable.
- No procesar adjuntos repetidos.
- No procesar PDFs de remitentes no autorizados.
- Confirmar manualmente el primer PDF detectado.

---

## 31. Trabajo en segundo plano

### 31.1 Revisión periódica

Usar `workmanager` para programar una tarea periódica.

Ejemplo conceptual:

```dart
Workmanager().registerPeriodicTask(
  'payrollEmailSync',
  'payrollEmailSyncTask',
  frequency: const Duration(hours: 6),
  constraints: Constraints(
    networkType: NetworkType.connected,
  ),
);
```

### 31.2 Recomendaciones

- No revisar cada minuto.
- Usar intervalo razonable: 6, 12 o 24 horas.
- Permitir sincronización manual inmediata.
- Mostrar última fecha de sincronización.
- Registrar errores sin exponer datos sensibles.

### 31.3 Limitación

Android puede retrasar tareas por batería, red, modo ahorro o políticas del fabricante. Por eso, el botón `Buscar ahora` debe estar siempre disponible.

---

## 32. Estrategia de fases de desarrollo

## Fase 1: Prototipo manual sin correo

### Objetivo

Validar el cálculo de horas y el dashboard sin depender de Gmail.

### Funciones

- Crear proyecto Flutter.
- Crear pantallas básicas.
- Registrar horas manualmente.
- Configurar porcentajes.
- Calcular deuda, pendiente y a favor.
- Guardar datos localmente.

### Entregables

- App Android funcional.
- Dashboard básico.
- Registro de horas.
- Historial mensual.

### Criterios de aceptación

- El usuario puede crear un mes con deuda inicial.
- El usuario puede registrar horas al 100%, 50% y 30%.
- El dashboard calcula correctamente.
- Los datos persisten al cerrar la app.

---

## Fase 2: Lectura de PDF local

### Objetivo

Permitir seleccionar un PDF manualmente y extraer información.

### Funciones

- Seleccionar PDF desde almacenamiento.
- Ingresar contraseña.
- Abrir PDF protegido.
- Extraer texto.
- Detectar saldo de horas.
- Permitir corrección manual.

### Entregables

- Procesador PDF local.
- Parser inicial.
- Pantalla de revisión de extracción.

### Criterios de aceptación

- La app abre al menos un PDF real de prueba.
- Extrae texto o informa claramente que no puede.
- Detecta saldo de horas o permite ingresarlo manualmente.

---

## Fase 3: Dashboard avanzado y reglas configurables

### Objetivo

Mejorar visualización, reglas y experiencia.

### Funciones

- Gráficos mensuales.
- Reglas editables de porcentajes.
- Estados visuales.
- Exportar resumen local.
- Validaciones robustas.

### Entregables

- Dashboard profesional.
- Pantalla de reglas.
- Historial mensual mejorado.

### Criterios de aceptación

- El usuario entiende claramente si debe horas o tiene a favor.
- Puede modificar factores de cálculo.
- Puede revisar meses anteriores.

---

## Fase 4: Conexión segura con Gmail

### Objetivo

Autorizar Gmail y buscar correos del remitente configurado.

### Funciones

- Google Sign-In.
- Scope `gmail.readonly`.
- Buscar mensajes.
- Listar PDFs encontrados.
- Descargar PDF seleccionado.

### Entregables

- Módulo Gmail.
- Pantalla de configuración de correo.
- Prueba de descarga de adjunto.

### Criterios de aceptación

- La app no solicita contraseña del correo.
- La app lista correos del remitente correcto.
- La app descarga el PDF adjunto.

---

## Fase 5: Automatización completa

### Objetivo

Revisar automáticamente correos y procesar nuevos roles.

### Funciones

- WorkManager periódico.
- Notificación local al encontrar PDF.
- Procesamiento automático si existe contraseña guardada.
- Prevención de duplicados.

### Entregables

- Sincronización periódica.
- Notificaciones.
- Logs de sincronización.

### Criterios de aceptación

- La app detecta un PDF nuevo sin intervención inmediata del usuario.
- No procesa dos veces el mismo archivo.
- Informa errores de forma clara.

---

## Fase 6: Seguridad, pruebas y publicación

### Objetivo

Preparar app para uso real y estable.

### Funciones

- Bloqueo biométrico opcional.
- Borrado seguro de datos.
- Pruebas unitarias.
- Pruebas de integración.
- Revisión de permisos.
- Política de privacidad.

### Entregables

- APK release.
- Documentación técnica.
- Manual de usuario.
- Checklist de seguridad.

### Criterios de aceptación

- No hay secretos en código fuente.
- La contraseña PDF está protegida.
- El usuario puede borrar todos sus datos.
- La app maneja errores sin exponer información sensible.

---

## 33. Plan de pruebas

### 33.1 Pruebas unitarias

| Prueba | Resultado esperado |
|---|---|
| Cálculo con deuda pendiente | Retorna estado `debt`. |
| Cálculo con pago exacto | Retorna estado `paid`. |
| Cálculo con sobrepago | Retorna estado `favor`. |
| Número con coma decimal | Convierte correctamente. |
| Número con punto decimal | Convierte correctamente. |
| Regex sin coincidencia | Retorna `failed`. |
| Horas negativas | Lanza error de validación. |

### 33.2 Pruebas de integración

| Caso | Resultado esperado |
|---|---|
| Seleccionar PDF válido | Extrae texto. |
| Contraseña incorrecta | Muestra error controlado. |
| PDF repetido | No duplica registro. |
| Gmail sin correos | Muestra mensaje vacío. |
| Gmail con adjunto no PDF | Lo ignora. |
| Sin internet | Permite modo local. |

### 33.3 Pruebas de seguridad

| Caso | Resultado esperado |
|---|---|
| Revisar código fuente | No contiene contraseña PDF ni correo quemado obligatoriamente. |
| Logs de error | No muestran contraseña ni texto completo del rol. |
| Cerrar sesión Google | Elimina estado de autenticación local. |
| Borrar datos | Limpia base, PDFs y contraseña. |
| Bloqueo biométrico | Solicita autenticación al abrir app. |

---

## 34. Manejo de errores

| Error | Acción de la app |
|---|---|
| No hay internet | Mostrar aviso y permitir modo local. |
| OAuth cancelado | Mantener app funcional en modo manual. |
| Permiso Gmail denegado | Explicar que no se puede automatizar correo. |
| No se encontró correo | Mostrar última búsqueda y permitir reintentar. |
| PDF sin adjunto | Ignorar correo y registrar evento. |
| Contraseña PDF incorrecta | Solicitar contraseña nuevamente. |
| PDF ilegible | Marcar como requiere revisión manual. |
| Parser no encuentra saldo | Permitir ingreso manual. |
| Duplicado detectado | No insertar y mostrar que ya fue procesado. |

---

## 35. Reglas de negocio principales

1. Solo se deben procesar correos del remitente configurado.
2. Solo se deben descargar adjuntos PDF.
3. Un mismo PDF no debe procesarse dos veces.
4. El usuario siempre puede corregir manualmente un saldo detectado.
5. El cálculo debe basarse en factores configurables.
6. El dashboard debe recalcularse cada vez que se inserta, edita o elimina un pago.
7. La contraseña del PDF nunca debe estar en logs ni código fuente.
8. La app debe funcionar en modo manual aunque Gmail no esté configurado.
9. El historial mensual no debe perderse al reprocesar un PDF.
10. Si se detecta otro PDF para el mismo mes, se debe pedir confirmación antes de reemplazar datos.

---

## 36. Configuración inicial recomendada

Al abrir por primera vez:

1. Mostrar bienvenida.
2. Preguntar si desea modo manual o conexión Gmail.
3. Solicitar remitente permitido.
4. Solicitar contraseña del PDF.
5. Crear reglas por defecto:
   - 100% → factor 1.00
   - 50% → factor 0.50
   - 30% → factor 0.30
6. Crear primer mes manual o buscar último rol.
7. Mostrar dashboard.

---

## 37. Consideraciones de publicación en Google Play

Si la app se publica para más personas:

- Se requiere política de privacidad.
- Puede requerirse verificación de OAuth si se usan scopes sensibles o restringidos.
- Debe justificarse el acceso a Gmail.
- Debe explicarse que solo se leen correos necesarios.
- Debe permitir eliminar datos.
- Debe proteger información laboral.

Para uso personal o pruebas internas, el proceso es más simple, pero igual debe cuidarse la seguridad.

---

## 38. Recomendaciones de implementación inmediata

Orden sugerido para empezar hoy:

1. Crear proyecto Flutter.
2. Implementar entidades de dominio.
3. Implementar cálculo de horas con pruebas unitarias.
4. Crear dashboard estático con datos simulados.
5. Crear formulario de registro de horas.
6. Guardar datos con Drift.
7. Agregar selección manual de PDF.
8. Probar extracción con PDF real.
9. Ajustar regex según el formato exacto del rol.
10. Recién después conectar Gmail API.

---

## 39. Checklist técnico por módulo

### 39.1 Módulo de horas

- [ ] Crear entidad `HourPayment`.
- [ ] Crear entidad `HourRateRule`.
- [ ] Crear servicio `HourBalanceCalculator`.
- [ ] Crear formulario de registro.
- [ ] Validar horas mayores a cero.
- [ ] Calcular horas efectivas.
- [ ] Recalcular dashboard después de guardar.

### 39.2 Módulo PDF

- [ ] Seleccionar PDF local.
- [ ] Guardar PDF en carpeta interna.
- [ ] Calcular SHA-256.
- [ ] Solicitar contraseña.
- [ ] Abrir PDF.
- [ ] Extraer texto.
- [ ] Aplicar parser.
- [ ] Mostrar pantalla de revisión.

### 39.3 Módulo Gmail

- [ ] Crear proyecto Google Cloud.
- [ ] Habilitar Gmail API.
- [ ] Configurar OAuth.
- [ ] Implementar Google Sign-In.
- [ ] Solicitar scope `gmail.readonly`.
- [ ] Buscar correos por remitente.
- [ ] Leer mensajes.
- [ ] Descargar adjuntos PDF.
- [ ] Evitar duplicados.

### 39.4 Módulo seguridad

- [ ] Guardar contraseña PDF con `flutter_secure_storage`.
- [ ] Evitar logs sensibles.
- [ ] Agregar bloqueo biométrico opcional.
- [ ] Agregar borrado total de datos.
- [ ] Guardar archivos solo en directorio interno.
- [ ] Evaluar cifrado de base local.

---

## 40. Riesgos técnicos y mitigación

| Riesgo | Impacto | Mitigación |
|---|---|---|
| PDF no permite extracción de texto | Alto | Usar OCR o backend. |
| Contraseña incorrecta | Medio | Solicitar reingreso y validar. |
| Gmail cambia permisos o requiere verificación | Medio | Usar scope mínimo y modo testing. |
| Android retrasa tareas en segundo plano | Medio | Usar WorkManager + sincronización manual. |
| Parser falla por cambios de formato | Alto | Crear plantillas versionadas y revisión manual. |
| Datos sensibles expuestos | Alto | Almacenamiento seguro, cifrado, no logs sensibles. |
| Duplicados por mismo correo | Medio | Usar messageId, attachmentId y hash. |
| Reglas de horas mal interpretadas | Alto | Hacer factores configurables y confirmación con usuario. |

---

## 41. Anexo A: Prompt recomendado para agente de Cursor

```text
Actúa como desarrollador senior experto en Flutter, Android, Clean Architecture, Riverpod, Drift/SQLite, Gmail API, OAuth 2.0, lectura de PDFs protegidos con contraseña, seguridad móvil y dashboards.

Necesito construir una aplicación Android en Flutter llamada Aplicación de Rol de Pagos.

Objetivo:
Crear una app que permita gestionar roles de pago mensuales en PDF protegidos con contraseña, extraer saldo de horas, registrar manualmente horas pagadas al 100%, 50%, 30% u otros porcentajes configurables, calcular horas adeudadas, pagadas, pendientes y horas a favor, y mostrar todo en un dashboard profesional.

Reglas de desarrollo:
1. Trabaja fase por fase. No avances a la siguiente fase hasta terminar la anterior.
2. Usa Clean Architecture.
3. Usa Riverpod para estado.
4. Usa Drift con SQLite para base de datos local.
5. Usa flutter_secure_storage para guardar la contraseña del PDF.
6. No guardes contraseñas en texto plano.
7. No quemes correos ni contraseñas en el código.
8. Primero implementa modo manual sin Gmail.
9. Luego implementa lectura de PDF local.
10. Después implementa dashboard y cálculos.
11. Finalmente implementa Gmail API con OAuth 2.0.
12. Todo debe estar en español para el usuario final.
13. Crea código limpio, modular y comentado cuando sea necesario.
14. Crea pruebas unitarias para la lógica de cálculo.
15. Evita logs con información sensible.

Fase 1:
Crear proyecto base, estructura de carpetas, entidades de dominio, cálculo de horas, dashboard con datos simulados y formulario para registrar horas.

Fase 2:
Agregar Drift/SQLite para persistir pagos, reglas de porcentajes y balances mensuales.

Fase 3:
Agregar selección manual de PDF, contraseña segura y extracción de texto desde PDF protegido.

Fase 4:
Crear parser flexible usando regex para detectar saldo de horas, con pantalla de revisión manual.

Fase 5:
Agregar Google Sign-In y Gmail API con scope gmail.readonly para buscar correos del remitente configurado y descargar PDFs adjuntos.

Fase 6:
Agregar WorkManager para sincronización periódica, notificaciones locales, prevención de duplicados y endurecimiento de seguridad.

Entrega cada fase con:
- Archivos creados.
- Código completo.
- Explicación corta.
- Comandos necesarios.
- Pruebas realizadas.
- Siguiente paso.
```

---

## 42. Anexo B: Manual corto de uso esperado

1. Abrir la app.
2. Configurar contraseña del PDF.
3. Crear reglas de horas o aceptar reglas por defecto.
4. Conectar Gmail o usar modo manual.
5. Buscar último rol de pago.
6. Confirmar datos extraídos.
7. Registrar horas pagadas cuando corresponda.
8. Revisar dashboard.
9. Consultar historial mensual.
10. Ajustar reglas si la empresa maneja otro cálculo.

---

## 43. Anexo C: Referencias técnicas usadas para el diseño

- Gmail API OAuth scopes: https://developers.google.com/workspace/gmail/api/auth/scopes
- Gmail API Push Notifications: https://developers.google.com/workspace/gmail/api/guides/push
- Gmail API Attachments: https://developers.google.com/workspace/gmail/api/reference/rest/v1/users.messages.attachments/get
- Android WorkManager: https://developer.android.com/develop/background-work/background-tasks/persistent
- Google Sign-In Flutter package: https://pub.dev/packages/google_sign_in
- Google APIs Dart package: https://pub.dev/packages/googleapis
- Flutter Secure Storage package: https://pub.dev/packages/flutter_secure_storage
- Drift package: https://pub.dev/packages/drift

---

## 44. Conclusión

La aplicación es técnicamente viable, pero debe construirse de forma progresiva. El punto más delicado no es la interfaz ni el cálculo, sino la extracción confiable del PDF protegido y la automatización del correo en segundo plano. Por eso se recomienda iniciar con un prototipo manual, validar el PDF real, ajustar el parser y luego agregar Gmail API.

La solución más segura y realista para la primera versión es:

- Flutter Android.
- Modo manual funcional.
- Drift para base de datos local.
- Flutter Secure Storage para contraseña del PDF.
- Parser flexible con revisión manual.
- Dashboard claro.
- Gmail API con OAuth como módulo posterior.
- WorkManager para revisión periódica.
- Backend opcional solo si se requiere automatización casi en tiempo real o procesamiento PDF avanzado.

Con esta arquitectura, el proyecto queda ordenado, seguro y preparado para crecer sin rehacer todo desde cero.


---

# PARTE II  
# Expediente técnico completo RolHoras original

# EXPEDIENTE TÉCNICO COMPLETO  
# Aplicación RolHoras – Control de horas, pagos, deudas y comparación con PDF

**Nombre del proyecto:** RolHoras  
**Tipo de sistema:** Aplicación móvil / web administrativa para control de horas  
**Plataforma sugerida:** Flutter + Firebase  
**Paquete Android sugerido:** `com.rolhoras.rol_pagos_app`  
**Versión del documento:** 1.0  
**Fecha:** 2026-04-30  
**Estado:** Documento base para desarrollo por fases en Cursor / agente de programación  

---

## 1. Presentación del proyecto

RolHoras es una aplicación diseñada para controlar, registrar, comparar y auditar saldos de horas de una persona o trabajador, tomando como base la información oficial contenida en documentos PDF y los registros ingresados manualmente por el usuario.

El sistema permitirá que el usuario cargue un PDF con información de horas, extraiga automáticamente los valores principales del documento y los compare con los datos registrados dentro de la aplicación, como horas pagadas, horas compensadas, horas adeudadas y ajustes manuales.

El objetivo principal es evitar errores en el control de horas, mantener un historial claro de movimientos y permitir que el usuario sepa en todo momento cuánto debe, cuánto ha pagado o compensado y si los datos coinciden con el documento oficial cargado.

---

## 2. Justificación

Actualmente, el control de horas puede generar confusión cuando se lleva de forma manual, especialmente si existen saldos negativos, pagos parciales, horas compensadas, deudas acumuladas o documentos PDF que contienen información oficial.

Por esta razón, la aplicación RolHoras debe funcionar como una herramienta de control y validación, permitiendo comparar tres fuentes de información:

1. Datos extraídos del PDF.
2. Datos ingresados manualmente por el usuario.
3. Historial interno de movimientos de horas.

De esta manera, el sistema ayudará a verificar si el saldo mostrado en el PDF coincide con los registros internos y permitirá detectar diferencias, inconsistencias o valores pendientes de revisión.

---

## 3. Objetivo general

Desarrollar una aplicación que permita registrar, calcular, comparar y auditar horas pagadas, compensadas y adeudadas, utilizando como respaldo la extracción automática de datos desde documentos PDF y la información ingresada por el usuario.

---

## 4. Objetivos específicos

- Permitir el inicio de sesión seguro de usuarios.
- Permitir la carga de documentos PDF de respaldo.
- Extraer automáticamente valores de horas desde el PDF.
- Mostrar en el dashboard los valores extraídos del PDF.
- Permitir registrar manualmente horas pagadas.
- Permitir registrar manualmente horas que el usuario debe.
- Calcular automáticamente el saldo interno de horas.
- Comparar el saldo calculado con el saldo actual extraído del PDF.
- Mostrar alertas visuales cuando existan diferencias.
- Guardar historial completo de movimientos.
- Generar reportes de control y auditoría.
- Mantener seguridad por roles y permisos.
- Permitir que el sistema sea escalable para más usuarios o trabajadores.

---

## 5. Alcance del sistema

### 5.1 Alcance funcional

El sistema debe permitir:

- Registro e inicio de sesión de usuarios.
- Gestión de perfil de usuario.
- Carga de documentos PDF.
- Extracción automática de información desde PDF.
- Registro de horas pagadas.
- Registro de horas que debe.
- Registro de horas compensadas.
- Registro de ajustes manuales.
- Visualización de resumen en dashboard.
- Comparación entre saldo PDF y saldo calculado.
- Historial de movimientos.
- Reportes filtrados por fecha.
- Exportación de información.
- Auditoría básica de acciones.

### 5.2 Alcance técnico

El proyecto puede desarrollarse con:

- Flutter para la aplicación.
- Firebase Authentication para login.
- Cloud Firestore para base de datos.
- Firebase Storage para guardar PDF.
- Cloud Functions o backend auxiliar para extracción avanzada de PDF, si se requiere.
- OCR opcional en caso de que el PDF no tenga texto seleccionable.

### 5.3 Fuera del alcance inicial

En la primera versión no se recomienda incluir:

- Nómina completa.
- Facturación electrónica.
- Firma electrónica.
- Integración bancaria.
- Inteligencia artificial avanzada.
- Reconocimiento complejo de documentos con múltiples formatos.

Estas funciones pueden planificarse para fases posteriores.

---

## 6. Usuarios y roles

### 6.1 Usuario administrador

Tiene acceso completo al sistema.

Funciones permitidas:

- Crear usuarios.
- Editar usuarios.
- Cargar PDF.
- Registrar horas.
- Registrar deudas.
- Registrar pagos.
- Ver todos los movimientos.
- Generar reportes.
- Revisar diferencias.
- Anular movimientos mediante ajustes.
- Acceder a auditoría.

### 6.2 Usuario operador

Puede registrar información operativa.

Funciones permitidas:

- Cargar PDF.
- Registrar horas pagadas.
- Registrar horas que debe.
- Consultar dashboard.
- Ver historial propio.
- Generar reportes básicos.

### 6.3 Usuario consulta

Solo puede visualizar información.

Funciones permitidas:

- Ver dashboard.
- Ver historial.
- Descargar reportes autorizados.

---

## 7. Módulos principales del sistema

1. Módulo de autenticación.
2. Módulo de dashboard.
3. Módulo de carga y lectura de PDF.
4. Módulo de extracción de datos del PDF.
5. Módulo de registro de horas pagadas.
6. Módulo de registro de horas que debe.
7. Módulo de cálculo de saldo.
8. Módulo de comparación y conciliación.
9. Módulo de historial de movimientos.
10. Módulo de reportes.
11. Módulo de configuración.
12. Módulo de auditoría.
13. Módulo de seguridad y permisos.

---

# 8. Módulo de autenticación

## 8.1 Descripción

El sistema debe contar con un inicio de sesión seguro para identificar al usuario que registra, modifica o consulta la información.

## 8.2 Funciones requeridas

- Inicio de sesión con correo y contraseña.
- Inicio de sesión con Google, si se mantiene en el proyecto.
- Cierre de sesión.
- Recuperación de contraseña.
- Validación de usuario activo.
- Restricción de acceso según rol.

## 8.3 Consideraciones para Google Sign-In

Si se usa Google Sign-In en Android, se debe configurar correctamente el cliente OAuth Android en Google Cloud o Firebase.

Datos importantes:

```text
Package name:
com.rolhoras.rol_pagos_app

SHA-1:
Debe corresponder a la clave usada para compilar la app.
```

Se debe crear un cliente OAuth Android con:

- Nombre del paquete correcto.
- SHA-1 correcto.
- Proyecto de Google Cloud correcto.
- Firebase conectado al mismo proyecto.

---

# 9. Módulo de dashboard principal

## 9.1 Descripción general

El dashboard será la pantalla principal del sistema. Debe mostrar de forma clara el estado actual de las horas, los valores extraídos desde el PDF, los valores ingresados manualmente por el usuario y el resultado de la comparación.

El dashboard no debe ser únicamente visual. Debe funcionar como un panel de control y auditoría.

## 9.2 Información que debe mostrar el dashboard

El dashboard debe mostrar:

| Elemento | Descripción |
|---|---|
| Saldo anterior PDF | Valor extraído del documento PDF |
| Horas compensadas PDF | Valor extraído del documento PDF |
| Saldo actual PDF | Valor extraído del documento PDF |
| Horas pagadas por el usuario | Total de horas ingresadas manualmente como pagadas |
| Horas que debe el usuario | Total de horas registradas como deuda |
| Ajustes manuales | Correcciones autorizadas |
| Saldo calculado por el sistema | Resultado según los movimientos internos |
| Diferencia | Diferencia entre PDF y sistema |
| Estado de conciliación | Coincide, No coincide o Requiere revisión |
| Último PDF cargado | Nombre y fecha del documento |
| Último movimiento | Último registro realizado |

## 9.3 Tarjetas sugeridas para el dashboard

El dashboard debe incluir tarjetas o cuadros resumen:

| Tarjeta | Contenido |
|---|---|
| Saldo anterior PDF | Muestra el saldo anterior leído del PDF |
| Horas compensadas PDF | Muestra las horas compensadas leídas del PDF |
| Saldo actual PDF | Muestra el saldo actual leído del PDF |
| Horas pagadas | Suma de horas pagadas registradas |
| Horas que debe | Suma de horas adeudadas registradas |
| Saldo interno | Saldo calculado por la aplicación |
| Diferencia | Diferencia entre saldo PDF y saldo interno |
| Estado | Resultado de la comparación |

## 9.4 Estados visuales

| Estado | Condición | Color sugerido |
|---|---|---|
| Coincide | La diferencia es 0.00 o está dentro de la tolerancia permitida | Verde |
| No coincide | Existe diferencia entre PDF y sistema | Rojo |
| Requiere revisión | Falta información o el PDF no pudo leerse correctamente | Amarillo |
| Sin PDF | Aún no se ha cargado ningún documento | Gris |
| Pendiente | Existen registros no conciliados | Naranja |

---

# 10. Módulo de carga y extracción de PDF

## 10.1 Descripción

El usuario podrá cargar un archivo PDF que contenga información oficial sobre el saldo de horas. El sistema deberá leer el documento y extraer automáticamente los valores principales.

## 10.2 Datos que debe extraer del PDF

El sistema debe extraer como mínimo los siguientes datos:

| Campo extraído | Descripción |
|---|---|
| Notas horas | Encabezado o sección donde se encuentra la información |
| Horas saldo anterior | Saldo acumulado antes del último movimiento |
| Horas compensadas | Horas que fueron compensadas o descontadas |
| Saldo actual | Saldo vigente mostrado en el PDF |

## 10.3 Ejemplo de datos extraídos

Ejemplo basado en el PDF o imagen de referencia:

| Campo | Valor |
|---|---:|
| Horas saldo anterior | -496.45 |
| Horas compensadas | 128.16 |
| Saldo actual | -368.29 |

## 10.4 Reglas de extracción

El sistema debe:

- Leer texto del PDF cuando el documento tenga texto seleccionable.
- Usar OCR solo si el PDF es una imagen escaneada.
- Reconocer números positivos y negativos.
- Reconocer valores con decimales.
- Conservar el signo negativo cuando exista.
- Conservar los decimales tal como aparecen en el documento.
- Asociar cada valor con su etiqueta correcta.
- Validar que el valor extraído sea numérico.
- Guardar el texto crudo extraído para auditoría.
- Permitir corrección manual si la extracción falla.

## 10.5 Etiquetas esperadas en el PDF

El sistema debe buscar etiquetas similares a:

```text
NOTAS HORAS
HORAS SALDO ANTERIOR
HORAS COMPENSADAS
SALDO ACTUAL
```

También debe considerar variaciones como:

```text
Saldo anterior
Horas saldo anterior
Horas compensadas
Saldo actual
Total actual
```

## 10.6 Validaciones del PDF

El sistema debe validar:

| Validación | Resultado esperado |
|---|---|
| El archivo debe ser PDF | Si no lo es, rechazar |
| El PDF debe pesar menos del límite definido | Si supera el límite, mostrar error |
| El PDF debe tener texto o imagen legible | Si no, marcar como requiere revisión |
| Debe encontrar al menos saldo actual | Si no lo encuentra, no confirmar extracción |
| Los valores deben ser numéricos | Si no, pedir revisión manual |
| No debe sobrescribir un PDF anterior sin confirmación | Debe crear un nuevo registro |

## 10.7 Confirmación posterior a la extracción

Después de extraer la información, el sistema debe mostrar una pantalla de revisión con:

| Campo | Valor extraído | Acción |
|---|---:|---|
| Horas saldo anterior | -496.45 | Confirmar / editar |
| Horas compensadas | 128.16 | Confirmar / editar |
| Saldo actual | -368.29 | Confirmar / editar |

El usuario debe confirmar antes de guardar definitivamente.

---

# 11. Módulo de registro de horas pagadas

## 11.1 Descripción

El sistema debe permitir que el usuario registre las horas que va pagando o compensando manualmente.

## 11.2 Campos requeridos

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| Fecha | Fecha | Sí | Día en que se registra el pago |
| Cantidad de horas | Decimal | Sí | Horas pagadas |
| Motivo | Texto | No | Motivo del pago |
| Observación | Texto | No | Comentario adicional |
| Documento relacionado | Archivo / referencia | No | PDF o respaldo asociado |
| Usuario que registra | Automático | Sí | Usuario autenticado |

## 11.3 Reglas de negocio

- Las horas pagadas aumentan el saldo cuando el saldo es negativo.
- No se deben aceptar valores vacíos.
- No se deben aceptar valores con texto no numérico.
- Se debe permitir decimales.
- Se debe guardar la fecha y el usuario que registró.
- No se debe eliminar físicamente un pago; debe anularse mediante un ajuste.

---

# 12. Módulo de registro de horas que debe

## 12.1 Descripción

El sistema debe permitir ingresar horas que el usuario todavía debe. Estas horas deben afectar el saldo calculado y mostrarse en el dashboard.

## 12.2 Campos requeridos

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| Fecha | Fecha | Sí | Fecha del registro |
| Cantidad de horas | Decimal | Sí | Horas que debe |
| Motivo | Texto | Sí | Razón de la deuda |
| Observación | Texto | No | Comentario adicional |
| Usuario que registra | Automático | Sí | Usuario autenticado |
| Estado | Lista | Sí | Pendiente, compensado o anulado |

## 12.3 Reglas de negocio

- Las horas que debe reducen el saldo o aumentan la deuda.
- Si el saldo está en negativo, una nueva deuda lo vuelve más negativo.
- Debe visualizarse en el dashboard.
- Debe quedar guardado en historial.
- No debe borrarse físicamente.
- Si se corrige, se debe registrar un ajuste.

---

# 13. Módulo de cálculo de saldo

## 13.1 Concepto de saldo

El saldo representa la diferencia actual entre horas adeudadas y horas compensadas.

Convención sugerida:

| Valor | Interpretación |
|---|---|
| Saldo negativo | El usuario debe horas |
| Saldo positivo | El usuario tiene horas a favor |
| Saldo cero | No existe deuda ni saldo a favor |

## 13.2 Fórmula base desde PDF

Con los datos del ejemplo:

```text
Saldo actual PDF = Horas saldo anterior + Horas compensadas
```

Ejemplo:

```text
-368.29 = -496.45 + 128.16
```

## 13.3 Fórmula de control interno

El sistema debe calcular el saldo interno considerando el PDF y los registros manuales.

```text
Saldo calculado =
Horas saldo anterior PDF
+ Horas compensadas PDF
+ Total horas pagadas manualmente
- Total horas que debe manualmente
+ Ajustes positivos
- Ajustes negativos
```

## 13.4 Fórmula de comparación

```text
Diferencia =
Saldo actual PDF - Saldo calculado por el sistema
```

## 13.5 Ejemplo correcto

```text
Horas saldo anterior PDF: -496.45
Horas compensadas PDF: 128.16
Horas pagadas manualmente: 0.00
Horas que debe manualmente: 0.00

Saldo calculado: -368.29
Saldo actual PDF: -368.29
Diferencia: 0.00
Estado: Coincide
```

## 13.6 Ejemplo con deuda manual

```text
Horas saldo anterior PDF: -496.45
Horas compensadas PDF: 128.16
Horas pagadas manualmente: 0.00
Horas que debe manualmente: 10.00

Saldo calculado: -378.29
Saldo actual PDF: -368.29
Diferencia: 10.00
Estado: No coincide
```

## 13.7 Ejemplo con pago manual

```text
Horas saldo anterior PDF: -496.45
Horas compensadas PDF: 128.16
Horas pagadas manualmente: 20.00
Horas que debe manualmente: 0.00

Saldo calculado: -348.29
Saldo actual PDF: -368.29
Diferencia: -20.00
Estado: No coincide
```

## 13.8 Tolerancia de comparación

Se recomienda una tolerancia configurable.

| Diferencia absoluta | Estado |
|---:|---|
| 0.00 | Coincide |
| 0.01 o menos | Coincide con tolerancia |
| Mayor a 0.01 | No coincide |

---

# 14. Módulo de comparación y conciliación

## 14.1 Descripción

La conciliación consiste en comparar los datos oficiales del PDF con los movimientos registrados dentro del sistema.

## 14.2 Resultado de conciliación

El sistema debe generar un resultado como:

| Elemento | Valor |
|---|---:|
| Saldo actual PDF | -368.29 |
| Saldo calculado sistema | -368.29 |
| Diferencia | 0.00 |
| Estado | Coincide |

## 14.3 Alertas

El sistema debe mostrar alertas cuando:

- El saldo del PDF no coincide con el saldo interno.
- El PDF no pudo leerse.
- Faltan datos obligatorios.
- Existen movimientos pendientes.
- Existen registros manuales sin documento de respaldo.
- La diferencia supera la tolerancia.
- El saldo cambia de negativo a positivo o de positivo a negativo.

## 14.4 Acciones de conciliación

Cuando exista diferencia, el sistema debe permitir:

- Revisar PDF cargado.
- Revisar valores extraídos.
- Revisar historial de pagos.
- Revisar historial de deudas.
- Registrar ajuste.
- Marcar como revisado.
- Agregar observación de conciliación.

---

# 15. Módulo de historial de movimientos

## 15.1 Descripción

Todo cambio relacionado con horas debe quedar registrado en un historial.

## 15.2 Tipos de movimientos

| Tipo | Descripción |
|---|---|
| CARGA_PDF | Registro generado al cargar un PDF |
| EXTRACCION_PDF | Registro de datos extraídos del PDF |
| PAGO_HORAS | Registro de horas pagadas |
| DEUDA_HORAS | Registro de horas que debe |
| COMPENSACION | Registro de compensación |
| AJUSTE_POSITIVO | Corrección que aumenta saldo |
| AJUSTE_NEGATIVO | Corrección que reduce saldo |
| ANULACION | Anulación lógica de un movimiento |
| CONCILIACION | Resultado de comparación PDF vs sistema |

## 15.3 Campos del historial

| Campo | Descripción |
|---|---|
| ID | Identificador único |
| Fecha | Fecha y hora del movimiento |
| Tipo de movimiento | Pago, deuda, ajuste, PDF, conciliación |
| Horas | Cantidad registrada |
| Saldo anterior | Saldo antes del movimiento |
| Saldo nuevo | Saldo después del movimiento |
| Usuario | Usuario que registró |
| Observación | Comentario |
| Documento asociado | PDF o respaldo |
| Estado | Activo, anulado o revisado |

## 15.4 Reglas del historial

- No se debe eliminar físicamente ningún movimiento.
- Toda corrección debe registrarse como ajuste.
- Debe poder filtrarse por fecha.
- Debe poder filtrarse por tipo.
- Debe poder exportarse.
- Debe mostrar quién realizó cada acción.

---

# 16. Módulo de reportes

## 16.1 Reportes requeridos

El sistema debe generar reportes de:

- Saldo actual.
- Historial de pagos.
- Historial de horas que debe.
- Historial de PDF cargados.
- Diferencias detectadas.
- Conciliaciones realizadas.
- Reporte mensual.
- Reporte por usuario.
- Reporte por rango de fechas.

## 16.2 Formatos sugeridos

- PDF.
- Excel.
- CSV.

## 16.3 Contenido mínimo del reporte

| Campo | Descripción |
|---|---|
| Nombre del usuario | Persona asociada al control |
| Fecha de generación | Fecha del reporte |
| Saldo anterior | Saldo inicial |
| Total compensado | Horas compensadas |
| Total pagado | Horas pagadas |
| Total adeudado | Horas que debe |
| Saldo actual | Saldo final |
| Diferencia | Diferencia con PDF |
| Estado | Resultado de conciliación |
| Observaciones | Comentarios registrados |

---

# 17. Módulo de configuración

## 17.1 Configuraciones requeridas

El sistema debe permitir configurar:

| Parámetro | Descripción |
|---|---|
| Tolerancia de diferencia | Valor máximo permitido para considerar coincidencia |
| Decimales | Cantidad de decimales a mostrar |
| Límite de PDF | Tamaño máximo permitido |
| Formato de fecha | Formato usado en reportes |
| Nombre de institución o empresa | Para reportes |
| Logo | Para reportes PDF |
| Roles | Permisos de acceso |
| Estados | Estados de conciliación |

---

# 18. Arquitectura técnica sugerida

## 18.1 Frontend

Tecnología sugerida:

```text
Flutter
```

La app debe organizarse por módulos o features.

Estructura sugerida:

```text
lib/
  core/
    constants/
    errors/
    utils/
    widgets/
    theme/
  features/
    auth/
      data/
      domain/
      presentation/
    dashboard/
      data/
      domain/
      presentation/
    pdf_hours/
      data/
      domain/
      presentation/
    hour_movements/
      data/
      domain/
      presentation/
    reports/
      data/
      domain/
      presentation/
    settings/
      data/
      domain/
      presentation/
  services/
    firebase_service.dart
    pdf_extraction_service.dart
    hour_calculation_service.dart
    audit_service.dart
  main.dart
```

## 18.2 Backend / Base de datos

Opción sugerida:

```text
Firebase
```

Servicios:

- Firebase Auth.
- Firestore.
- Firebase Storage.
- Cloud Functions opcional.

## 18.3 Almacenamiento de archivos

Los PDF cargados deben guardarse en Firebase Storage o almacenamiento seguro equivalente.

Ruta sugerida:

```text
pdf_hours/{userId}/{year}/{documentId}.pdf
```

## 18.4 Procesamiento del PDF

Opciones:

1. Procesamiento dentro de Flutter si el PDF tiene texto.
2. Procesamiento mediante backend si se requiere OCR.
3. Procesamiento mediante Cloud Functions para mayor seguridad.

---

# 19. Modelo de datos sugerido en Firestore

## 19.1 Colección users

```json
{
  "uid": "string",
  "displayName": "string",
  "email": "string",
  "role": "admin | operator | viewer",
  "active": true,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## 19.2 Colección hour_documents

```json
{
  "id": "string",
  "userId": "string",
  "fileName": "reporte_horas.pdf",
  "fileUrl": "string",
  "storagePath": "string",
  "uploadedAt": "timestamp",
  "uploadedBy": "uid",
  "rawText": "string",
  "extractionStatus": "success | partial | failed | manual_review",
  "previousBalance": -496.45,
  "compensatedHours": 128.16,
  "currentBalance": -368.29,
  "extractionConfidence": 0.95,
  "confirmed": true,
  "confirmedAt": "timestamp",
  "confirmedBy": "uid"
}
```

## 19.3 Colección hour_movements

```json
{
  "id": "string",
  "userId": "string",
  "type": "PAGO_HORAS | DEUDA_HORAS | AJUSTE_POSITIVO | AJUSTE_NEGATIVO | COMPENSACION",
  "hours": 10.00,
  "date": "timestamp",
  "reason": "string",
  "observation": "string",
  "relatedDocumentId": "string",
  "createdAt": "timestamp",
  "createdBy": "uid",
  "status": "active | cancelled",
  "cancelReason": "string",
  "cancelledAt": "timestamp",
  "cancelledBy": "uid"
}
```

## 19.4 Colección hour_balances

```json
{
  "userId": "string",
  "lastDocumentId": "string",
  "pdfPreviousBalance": -496.45,
  "pdfCompensatedHours": 128.16,
  "pdfCurrentBalance": -368.29,
  "manualPaidHours": 0.00,
  "manualDebtHours": 0.00,
  "positiveAdjustments": 0.00,
  "negativeAdjustments": 0.00,
  "systemCalculatedBalance": -368.29,
  "difference": 0.00,
  "status": "coincide | no_coincide | requiere_revision | sin_pdf",
  "updatedAt": "timestamp"
}
```

## 19.5 Colección audit_logs

```json
{
  "id": "string",
  "userId": "string",
  "action": "string",
  "entity": "string",
  "entityId": "string",
  "oldValue": {},
  "newValue": {},
  "createdAt": "timestamp",
  "createdBy": "uid",
  "deviceInfo": "string"
}
```

---

# 20. Reglas de seguridad

## 20.1 Reglas generales

- Solo usuarios autenticados pueden ingresar.
- Cada usuario solo debe acceder a su información, salvo administrador.
- Los PDF deben estar protegidos.
- Los movimientos no deben eliminarse físicamente.
- Los ajustes deben quedar auditados.
- Los roles deben validarse en frontend y base de datos.

## 20.2 Roles

| Acción | Admin | Operador | Consulta |
|---|---|---|---|
| Ver dashboard | Sí | Sí | Sí |
| Cargar PDF | Sí | Sí | No |
| Registrar pagos | Sí | Sí | No |
| Registrar deuda | Sí | Sí | No |
| Crear usuarios | Sí | No | No |
| Anular movimientos | Sí | No | No |
| Exportar reportes | Sí | Sí | Sí |
| Ver auditoría | Sí | No | No |

---

# 21. Diseño visual sugerido

## 21.1 Estilo general

El diseño debe ser:

- Limpio.
- Profesional.
- Fácil de leer.
- Con tarjetas de resumen.
- Con colores por estado.
- Adaptado para celular.
- Con posibilidad de adaptarse a web o escritorio.

## 21.2 Pantallas requeridas

1. Login.
2. Recuperar contraseña.
3. Dashboard.
4. Cargar PDF.
5. Confirmar datos extraídos.
6. Registrar horas pagadas.
7. Registrar horas que debe.
8. Historial de movimientos.
9. Detalle de movimiento.
10. Reportes.
11. Configuración.
12. Administración de usuarios.

## 21.3 Dashboard visual sugerido

El dashboard debe tener:

```text
[Saldo actual PDF]       [Saldo calculado]
[Horas compensadas]      [Horas pagadas]
[Horas que debe]         [Diferencia]
[Estado de conciliación]
[Último PDF cargado]
[Últimos movimientos]
```

---

# 22. Flujos principales del sistema

## 22.1 Flujo de carga de PDF

1. El usuario inicia sesión.
2. Ingresa al dashboard.
3. Selecciona “Cargar PDF”.
4. Elige un archivo PDF.
5. El sistema valida el archivo.
6. El sistema extrae los datos.
7. El sistema muestra una pantalla de confirmación.
8. El usuario confirma o corrige los valores.
9. El sistema guarda el PDF.
10. El sistema actualiza el dashboard.
11. El sistema registra el movimiento en historial.

## 22.2 Flujo de registro de horas pagadas

1. El usuario ingresa al dashboard.
2. Selecciona “Registrar pago”.
3. Ingresa fecha, horas y observación.
4. El sistema valida los datos.
5. El sistema guarda el movimiento.
6. El sistema recalcula el saldo.
7. El dashboard se actualiza.
8. El historial registra el movimiento.

## 22.3 Flujo de registro de horas que debe

1. El usuario ingresa al dashboard.
2. Selecciona “Registrar deuda”.
3. Ingresa fecha, cantidad de horas, motivo y observación.
4. El sistema valida los datos.
5. El sistema guarda el movimiento.
6. El sistema recalcula el saldo.
7. El dashboard muestra la nueva deuda.
8. El historial registra el movimiento.

## 22.4 Flujo de conciliación

1. El sistema toma el último PDF confirmado.
2. Suma los movimientos manuales.
3. Calcula el saldo interno.
4. Compara con el saldo actual del PDF.
5. Calcula la diferencia.
6. Determina el estado.
7. Muestra el resultado en el dashboard.
8. Guarda el resultado de conciliación.

---

# 23. Validaciones obligatorias

## 23.1 Validaciones de campos numéricos

- No permitir letras.
- No permitir campos vacíos.
- Permitir decimales.
- Permitir valores negativos solo cuando corresponda.
- Normalizar separador decimal.
- Evitar valores duplicados accidentales.

## 23.2 Validaciones de fecha

- La fecha no puede estar vacía.
- La fecha no debe ser futura, salvo configuración especial.
- Debe permitir filtrar por rango.

## 23.3 Validaciones de PDF

- Debe ser PDF.
- Debe tener tamaño permitido.
- Debe poder leerse.
- Debe contener al menos un valor de saldo.
- Debe guardarse con referencia al usuario.

## 23.4 Validaciones de movimientos

- Todo movimiento debe tener usuario creador.
- Todo movimiento debe tener fecha.
- Todo movimiento debe tener tipo.
- Todo movimiento debe afectar el saldo según su tipo.
- Las anulaciones no eliminan el registro original.

---

# 24. Manejo de errores

## 24.1 Errores posibles

| Error | Mensaje sugerido |
|---|---|
| PDF inválido | El archivo seleccionado no es un PDF válido |
| PDF no legible | No se pudo leer la información del documento |
| Dato no encontrado | No se encontró el campo solicitado en el PDF |
| Valor inválido | El valor ingresado no es numérico |
| Sin conexión | No se pudo conectar con el servidor |
| Permiso denegado | No tiene permisos para realizar esta acción |
| Error de login | Credenciales incorrectas |
| Diferencia detectada | El saldo del PDF no coincide con el saldo calculado |

## 24.2 Reglas de mensajes

Los mensajes deben ser claros y útiles.

Ejemplo incorrecto:

```text
Error 500
```

Ejemplo correcto:

```text
No se pudo guardar el registro de horas. Revise su conexión e inténtelo nuevamente.
```

---

# 25. Criterios de aceptación general

| N.º | Criterio |
|---:|---|
| 1 | El usuario puede iniciar sesión correctamente |
| 2 | El dashboard muestra información clara |
| 3 | El usuario puede cargar un PDF |
| 4 | El sistema extrae saldo anterior, horas compensadas y saldo actual |
| 5 | El usuario puede confirmar o corregir los datos extraídos |
| 6 | El sistema guarda el PDF como respaldo |
| 7 | El usuario puede registrar horas pagadas |
| 8 | El usuario puede registrar horas que debe |
| 9 | El sistema calcula el saldo interno |
| 10 | El sistema compara saldo PDF vs saldo interno |
| 11 | El dashboard muestra diferencia y estado |
| 12 | El historial registra todos los movimientos |
| 13 | Los movimientos no se eliminan físicamente |
| 14 | El sistema permite reportes básicos |
| 15 | Los permisos funcionan según rol |
| 16 | La aplicación funciona correctamente en Android |
| 17 | La información se mantiene segura |
| 18 | Los errores muestran mensajes comprensibles |
| 19 | Se puede probar cada módulo por separado |
| 20 | Cada fase terminada incluye guía de prueba |

---

# 26. Plan de desarrollo por fases

## Fase 1: Base del proyecto

### Objetivo

Crear la estructura inicial del proyecto Flutter.

### Tareas

- Crear proyecto Flutter.
- Configurar nombre de app.
- Configurar paquete Android.
- Crear estructura de carpetas.
- Configurar tema.
- Crear navegación base.
- Crear pantalla inicial.

### Resultado esperado

La aplicación debe abrir correctamente y mostrar una pantalla inicial.

### Estado obligatorio al finalizar

```text
## Estado
Listo para probar

## Qué se puede probar
La aplicación inicia correctamente y muestra la pantalla inicial.

## Cómo probar
Ejecutar flutter run y verificar que la app abre sin errores.
```

---

## Fase 2: Autenticación

### Objetivo

Implementar login y control de sesión.

### Tareas

- Configurar Firebase.
- Agregar Firebase Auth.
- Crear pantalla de login.
- Crear recuperación de contraseña.
- Crear cierre de sesión.
- Proteger rutas.

### Resultado esperado

El usuario puede iniciar y cerrar sesión.

---

## Fase 3: Dashboard inicial

### Objetivo

Crear el dashboard principal con tarjetas vacías o datos simulados.

### Tareas

- Crear pantalla dashboard.
- Crear tarjetas de saldo.
- Crear tarjetas de horas pagadas.
- Crear tarjetas de horas que debe.
- Crear tarjeta de estado.
- Crear sección de últimos movimientos.

### Resultado esperado

El dashboard se visualiza correctamente.

---

## Fase 4: Carga de PDF

### Objetivo

Permitir seleccionar y subir documentos PDF.

### Tareas

- Agregar selector de archivos.
- Validar PDF.
- Subir PDF a Storage.
- Guardar referencia en Firestore.
- Mostrar último PDF cargado.

### Resultado esperado

El usuario puede cargar un PDF y verlo registrado.

---

## Fase 5: Extracción de datos del PDF

### Objetivo

Extraer automáticamente los valores de horas desde el PDF.

### Tareas

- Leer texto del PDF.
- Buscar etiquetas.
- Extraer valores numéricos.
- Validar valores.
- Mostrar pantalla de confirmación.
- Guardar valores confirmados.

### Resultado esperado

El sistema extrae:

- Horas saldo anterior.
- Horas compensadas.
- Saldo actual.

---

## Fase 6: Registro de horas pagadas

### Objetivo

Permitir registrar pagos o compensaciones manuales.

### Tareas

- Crear formulario.
- Validar horas.
- Guardar movimiento.
- Actualizar dashboard.
- Registrar historial.

### Resultado esperado

El usuario puede ingresar horas pagadas y el saldo se actualiza.

---

## Fase 7: Registro de horas que debe

### Objetivo

Permitir registrar deudas de horas.

### Tareas

- Crear formulario.
- Validar horas.
- Guardar deuda.
- Actualizar dashboard.
- Registrar historial.

### Resultado esperado

El usuario puede ingresar horas que debe y el saldo se actualiza.

---

## Fase 8: Cálculo y comparación

### Objetivo

Calcular saldo interno y comparar con el PDF.

### Tareas

- Crear servicio de cálculo.
- Sumar pagos.
- Sumar deudas.
- Aplicar ajustes.
- Calcular diferencia.
- Definir estado.
- Mostrar resultado en dashboard.

### Resultado esperado

El sistema muestra si los datos coinciden o no.

---

## Fase 9: Historial

### Objetivo

Mostrar todos los movimientos.

### Tareas

- Crear pantalla de historial.
- Filtrar por fecha.
- Filtrar por tipo.
- Ver detalle.
- Anular mediante ajuste.

### Resultado esperado

El usuario puede revisar todos los registros.

---

## Fase 10: Reportes

### Objetivo

Generar reportes básicos.

### Tareas

- Crear reporte visual.
- Exportar PDF.
- Exportar CSV.
- Exportar Excel si se requiere.
- Agregar filtros.

### Resultado esperado

El usuario puede generar y descargar reportes.

---

## Fase 11: Seguridad y permisos

### Objetivo

Proteger datos y acciones.

### Tareas

- Definir roles.
- Aplicar permisos en frontend.
- Aplicar reglas en Firestore.
- Proteger Storage.
- Registrar auditoría.

### Resultado esperado

Cada usuario solo accede a lo permitido.

---

## Fase 12: Pulido final

### Objetivo

Mejorar diseño, errores y experiencia de usuario.

### Tareas

- Mejorar interfaz.
- Ajustar colores.
- Optimizar carga.
- Revisar errores.
- Probar en Android.
- Generar APK.

### Resultado esperado

Aplicación lista para pruebas finales.

---

# 27. Reglas obligatorias para el agente de Cursor

Estas reglas deben colocarse en el apartado de reglas del agente de Cursor para que el desarrollo sea ordenado.

## 27.1 Regla de desarrollo por fases

El agente debe desarrollar el sistema fase por fase. No debe mezclar varias fases al mismo tiempo si eso genera errores o dificulta la prueba.

Antes de iniciar una fase, debe revisar:

- Estado actual del proyecto.
- Archivos existentes.
- Errores actuales.
- Dependencias instaladas.
- Módulo que se va a modificar.

## 27.2 Regla de no romper lo existente

El agente no debe eliminar código funcional sin explicar la razón.  
Debe conservar lo que ya funciona y modificar solo lo necesario.

## 27.3 Regla de archivos completos

Cuando se modifique un archivo importante, el agente debe entregar el archivo completo si el cambio es grande.

## 27.4 Regla de rutas claras

Cada archivo creado o modificado debe indicar su ruta exacta.

Ejemplo:

```text
lib/features/dashboard/presentation/pages/dashboard_page.dart
```

## 27.5 Regla de prueba obligatoria

Cada vez que complete un proceso, una funcionalidad, una corrección, una pantalla, un módulo o una integración, y el resultado ya esté listo para probarse, debe avisarlo de forma obligatoria al usuario.

No debe cerrar una respuesta solo diciendo que ya terminó. Debe indicar claramente que el proceso ya puede probarse y explicar exactamente qué debe hacer el usuario para validarlo.

Formato obligatorio:

```text
## Estado
Listo para probar

## Qué se puede probar
Debe explicar qué funcionalidad quedó lista.

## Cómo probar
Debe explicar paso a paso qué debe hacer el usuario para validar.

## Resultado esperado
Debe indicar qué debe observar el usuario si todo está correcto.
```

## 27.6 Estados permitidos

El agente debe usar uno de estos estados:

```text
Listo para probar
Listo parcialmente para probar
Requiere un paso previo antes de probar
```

## 27.7 Regla para errores

Si existe un error, el agente debe explicar:

- Qué error encontró.
- En qué archivo ocurre.
- Por qué ocurre.
- Qué cambió para corregirlo.
- Cómo probar la corrección.

## 27.8 Regla para Firebase y Google Cloud

El agente no debe inventar credenciales.  
Si se requiere Firebase, debe indicar exactamente qué dato necesita el usuario.

Debe respetar:

```text
Package name:
com.rolhoras.rol_pagos_app
```

Debe recordar que para Google Sign-In se necesita:

- OAuth Android Client.
- SHA-1 correcto.
- Proyecto correcto.
- Firebase conectado.

## 27.9 Regla para extracción PDF

El agente debe implementar la extracción del PDF de forma progresiva:

1. Primero lectura de texto.
2. Luego búsqueda de etiquetas.
3. Luego extracción numérica.
4. Luego confirmación manual.
5. Luego guardado.
6. Luego comparación.

No debe iniciar con OCR complejo si primero no se prueba la lectura normal del PDF.

## 27.10 Regla para cálculos

El agente debe centralizar los cálculos en un servicio único.

Archivo sugerido:

```text
lib/services/hour_calculation_service.dart
```

No debe repetir fórmulas en varias pantallas.

## 27.11 Regla para auditoría

Cada movimiento importante debe crear un registro de auditoría.

Movimientos importantes:

- Carga de PDF.
- Confirmación de extracción.
- Registro de pago.
- Registro de deuda.
- Ajuste.
- Anulación.
- Conciliación.

---

# 28. Prompt maestro para Cursor

Este prompt puede usarse para iniciar el desarrollo en Cursor.

```text
Actúa como un desarrollador senior experto en Flutter, Firebase, arquitectura limpia, control de estados, extracción de PDF y buenas prácticas de seguridad.

Vas a desarrollar una aplicación llamada RolHoras, cuyo objetivo es controlar horas pagadas, horas compensadas, horas adeudadas y comparar esos datos con valores extraídos desde un PDF.

Debes trabajar fase por fase, sin romper lo que ya existe.

La aplicación debe permitir:
1. Iniciar sesión.
2. Mostrar dashboard.
3. Cargar PDF.
4. Extraer del PDF:
   - Horas saldo anterior.
   - Horas compensadas.
   - Saldo actual.
5. Mostrar esos datos en el dashboard.
6. Permitir ingresar horas pagadas.
7. Permitir ingresar horas que debe.
8. Calcular saldo interno.
9. Comparar saldo interno con saldo actual del PDF.
10. Mostrar diferencia y estado:
    - Coincide.
    - No coincide.
    - Requiere revisión.
11. Guardar historial de movimientos.
12. Generar reportes.
13. Respetar roles y permisos.
14. Registrar auditoría.

Reglas obligatorias:
- Trabaja por fases.
- Indica siempre los archivos modificados.
- No elimines código funcional sin justificar.
- Entrega archivos completos cuando el cambio sea grande.
- Centraliza cálculos en un servicio.
- Centraliza lectura de PDF en un servicio.
- No dupliques lógica.
- Usa nombres claros.
- Mantén estructura ordenada.
- Al finalizar cada proceso listo para probar, debes responder con:

## Estado
Listo para probar / Listo parcialmente para probar / Requiere un paso previo antes de probar

## Qué se puede probar
Explica la funcionalidad terminada.

## Cómo probar
Da pasos exactos para validar.

## Resultado esperado
Indica qué debe observarse si funciona correctamente.

Inicia revisando el proyecto actual y proponiendo la Fase 1 sin modificar todo de golpe.
```

---

# 29. Guía de pruebas generales

## 29.1 Prueba de inicio de sesión

### Pasos

1. Abrir la aplicación.
2. Ingresar correo y contraseña.
3. Presionar iniciar sesión.

### Resultado esperado

El usuario ingresa al dashboard.

---

## 29.2 Prueba de carga de PDF

### Pasos

1. Ingresar al dashboard.
2. Presionar “Cargar PDF”.
3. Seleccionar un archivo PDF.
4. Confirmar carga.

### Resultado esperado

El PDF se guarda y aparece como último documento cargado.

---

## 29.3 Prueba de extracción de PDF

### Pasos

1. Cargar PDF con datos de horas.
2. Esperar lectura.
3. Revisar los valores extraídos.
4. Confirmar.

### Resultado esperado

El sistema identifica:

```text
Horas saldo anterior
Horas compensadas
Saldo actual
```

---

## 29.4 Prueba de comparación

### Pasos

1. Cargar un PDF con:
   - Horas saldo anterior: -496.45
   - Horas compensadas: 128.16
   - Saldo actual: -368.29
2. Confirmar datos.
3. Revisar dashboard.

### Resultado esperado

El dashboard debe mostrar:

```text
Saldo calculado: -368.29
Diferencia: 0.00
Estado: Coincide
```

---

## 29.5 Prueba de horas pagadas

### Pasos

1. Ir a “Registrar pago”.
2. Ingresar 20.00 horas.
3. Guardar.
4. Regresar al dashboard.

### Resultado esperado

El saldo calculado debe aumentar 20.00 horas respecto al saldo anterior.

---

## 29.6 Prueba de horas que debe

### Pasos

1. Ir a “Registrar deuda”.
2. Ingresar 10.00 horas.
3. Guardar.
4. Regresar al dashboard.

### Resultado esperado

El saldo calculado debe disminuir 10.00 horas respecto al saldo anterior.

---

## 29.7 Prueba de historial

### Pasos

1. Registrar un pago.
2. Registrar una deuda.
3. Cargar un PDF.
4. Abrir historial.

### Resultado esperado

Deben aparecer todos los movimientos con fecha, tipo, horas y usuario.

---

# 30. Requisitos no funcionales

## 30.1 Rendimiento

- El dashboard debe cargar rápido.
- La lectura de PDF no debe bloquear la interfaz.
- Los reportes deben generarse sin congelar la app.

## 30.2 Seguridad

- Los datos deben estar protegidos por usuario.
- Los PDF no deben ser públicos.
- Los roles deben validarse.
- Las reglas de Firestore deben impedir acceso no autorizado.

## 30.3 Usabilidad

- La app debe ser fácil de usar.
- Los botones deben ser claros.
- Los mensajes deben ser comprensibles.
- Los estados deben ser visibles.

## 30.4 Mantenibilidad

- Código separado por módulos.
- Servicios centralizados.
- Nombres claros.
- Evitar duplicación.
- Documentar reglas de cálculo.

## 30.5 Escalabilidad

El sistema debe poder crecer para:

- Más usuarios.
- Más documentos.
- Más reportes.
- Más roles.
- Más tipos de movimientos.

---

# 31. Riesgos técnicos y soluciones

| Riesgo | Solución |
|---|---|
| PDF no tiene texto seleccionable | Usar OCR como fase posterior |
| Google Sign-In falla por SHA-1 | Revisar OAuth Android Client |
| Cálculos duplicados | Centralizar en servicio |
| Usuario borra registros por error | Usar anulación lógica |
| Diferencias por decimales | Usar tolerancia y decimales controlados |
| PDF con formato diferente | Permitir corrección manual |
| Falta de conexión | Mostrar mensajes y reintentar |
| Reglas Firebase mal configuradas | Probar roles antes de producción |

---

# 32. Recomendaciones finales de implementación

1. Desarrollar primero el dashboard con datos simulados.
2. Luego implementar carga de PDF.
3. Después implementar extracción simple de texto.
4. Luego implementar confirmación manual.
5. Después implementar movimientos de pagos y deudas.
6. Luego crear el cálculo centralizado.
7. Finalmente implementar reportes y auditoría.
8. No implementar OCR hasta confirmar que la lectura normal del PDF funciona.
9. No mezclar lógica de cálculo dentro de pantallas.
10. No permitir eliminación física de movimientos.
11. Probar cada fase antes de avanzar.

---

# 33. Definición de terminado del proyecto

El proyecto se considera terminado cuando:

- La aplicación permite iniciar sesión.
- El dashboard muestra datos reales.
- El usuario puede cargar PDF.
- El sistema extrae datos principales del PDF.
- El usuario puede confirmar o corregir la extracción.
- El usuario puede registrar horas pagadas.
- El usuario puede registrar horas que debe.
- El sistema calcula el saldo.
- El sistema compara contra el PDF.
- El sistema muestra diferencia y estado.
- El historial funciona.
- Los reportes básicos funcionan.
- Los permisos funcionan.
- La aplicación puede instalarse en Android.
- El sistema puede ser probado por un usuario final.

---

# 34. Resumen ejecutivo

RolHoras será una aplicación de control de horas enfocada en precisión, trazabilidad y comparación con documentos oficiales en PDF.

El sistema no dependerá únicamente de lo que el usuario escriba manualmente. Tendrá una validación cruzada entre los datos extraídos del PDF, los movimientos internos y el saldo calculado.

El dashboard será el centro principal de control, mostrando saldos, pagos, deudas, diferencias y estados de conciliación.

El desarrollo debe realizarse por fases y cada fase debe terminar con una guía clara de prueba para que el usuario pueda validar el avance.

---

# 35. Anexo: ejemplo visual de datos del PDF

Datos identificados en el documento de referencia:

```text
NOTAS HORAS

HORAS SALDO ANTERIOR       -496.45
HORAS COMPENSADAS           128.16
SALDO ACTUAL               -368.29
```

Interpretación:

```text
Saldo anterior negativo:
El usuario tenía una deuda de 496.45 horas.

Horas compensadas:
Se compensaron 128.16 horas.

Saldo actual:
Después de la compensación, aún queda un saldo negativo de 368.29 horas.
```

Cálculo:

```text
-496.45 + 128.16 = -368.29
```

Resultado:

```text
El cálculo coincide con el saldo actual mostrado en el PDF.
```


---

# Cierre del documento consolidado

Este archivo integra en un solo documento el contenido completo de los dos expedientes técnicos entregados para el proyecto RolHoras.
