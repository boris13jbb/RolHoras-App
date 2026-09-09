# GUÍA DE PRUEBAS EN DISPOSITIVO REAL — RolHoras-App

## Estado Actual

La aplicación está **lista para pruebas en dispositivo Android real**. Se han corregido los 4 errores principales:

1. ✅ Manejo robusto de excepciones en Gmail Auth
2. ✅ Validación de contraseña PDF antes de marcar como procesado
3. ✅ Persistencia de Gmail al reabrir app
4. ✅ Logs y validación en extracción de período

## Preparación Previa

### Paso 1: Verificar APK disponible
```bash
# La APK debug ya fue generada en:
build/app/outputs/flutter-apk/app-debug.apk

# Si no existe, generar nueva:
flutter clean
flutter pub get
flutter build apk --debug
```

### Paso 2: Configurar Google Cloud (obligatorio)

**Sin esto, Gmail local NO funcionará.**

1. Ve a [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Proyecto: `rol-pagos-saas-b7b04`
3. Credenciales → OAuth 2.0 → Tipo: **Android**
   - Package Name: `com.rolhoras.rol_pagos_app`
   - SHA-1 Fingerprint (debug): `1F:A2:55:83:72:66:EC:08:9F:5D:FC:6C:5B:86:2C:98:6E:53:7C:ED`
4. Credenciales → OAuth 2.0 → Tipo: **Web application**
   - Recomendado: `398451651219-6lblq3morscifre6ka35jmtk01db4k0l.apps.googleusercontent.com`
5. Descargar `google-services.json` (debe incluir oauth_client)

### Paso 3: Instalar APK en dispositivo

```bash
# Conectar dispositivo Android por USB con depuración activada
adb devices

# Instalar APK
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Ver logs en tiempo real
flutter logs
```

## Flujos de Prueba

### A. Prueba 1: Navegación Básica

**Objetivo:** Verificar que la app inicia y navega correctamente.

| Acción | Esperado | Estado |
|--------|----------|--------|
| Abrir app | Pantalla de inicio (Dashboard) | ⬜ |
| Tocar "Historial" (tab) | Muestra lista de roles (vacía inicialmente) | ⬜ |
| Tocar "Ajustes" (tab) | Muestra secciones: PDF, Remitente, Gmail | ⬜ |
| Tocar "Configuración" (tab) | Acceso a perfil/configuración general | ⬜ |

---

### B. Prueba 2: Importar PDF Local

**Objetivo:** Cargar un PDF desde almacenamiento y procesarlo.

**Requisitos:**
- Tener un PDF de rol en el dispositivo
- Contraseña del PDF (si está protegido)

| Acción | Esperado | Estado |
|--------|----------|--------|
| Ir a Historial → Botón "+" | Diálogo para seleccionar archivo | ⬜ |
| Seleccionar PDF local | Archivo se carga y aparece en la lista | ⬜ |
| Tocar el PDF cargado | Menú de opciones: Ver, Procesar, Eliminar | ⬜ |
| Procesar sin contraseña guardada | Pide contraseña en diálogo | ⬜ |
| Ingresar contraseña correcta | PDF se procesa, se extraen horas | ⬜ |
| Revisar "Datos detectados" | Muestra horas adeudadas, pagadas, pendientes | ⬜ |
| Guardar contraseña (Ajustes) | Se almacena en almacenamiento seguro | ⬜ |
| Procesar nuevo PDF con contraseña guardada | Procesa automáticamente sin pedir | ⬜ |

---

### C. Prueba 3: Configuración Gmail (Local)

**Objetivo:** Conectar Gmail y sincronizar PDFs desde el correo.

**Requisitos:**
- Cliente OAuth Web ID configurado en Google Cloud
- Cuenta Gmail con rolesa en la bandeja de entrada

| Acción | Esperado | Estado |
|--------|----------|--------|
| Ir a Ajustes → "Gmail local" | Sección OAuth expandible | ⬜ |
| Tocar "Usar Client ID de rol-pagos-saas" | Campo se llena automáticamente | ⬜ |
| Tocar "Guardar Client ID" | Mensaje: "Client ID guardado..." | ⬜ |
| Tocar "Conectar Gmail" | Se abre pantalla de Google Sign-In | ⬜ |
| Seleccionar cuenta Gmail | Vuelve a la app, muestra correo conectado | ⬜ |
| Tocar en campo "Remitente del rol" | Ingresa correo de quien envía roles (ej. nomina@empresa.com) | ⬜ |
| Tocar "Guardar remitente" | Se guarda y persiste | ⬜ |
| Tocar "Sincronizar" | Mensaje con desglose: importados, procesados, pendientes | ⬜ |
| Cerrar y reabrir app | Remitente aún está guardado | ⬜ |
| Verificar estado de Gmail | Sigue conectado y remitente cargado | ⬜ |

---

### D. Prueba 4: Conciliación de Datos

**Objetivo:** Verificar que la app compara PDF vs balance interno.

| Acción | Esperado | Estado |
|--------|----------|--------|
| Procesar varios PDFs con horas | Dashboard muestra suma de horas | ⬜ |
| Revisar "Diferencia detectada" (si aplica) | Alerta si saldo PDF ≠ saldo app | ⬜ |
| Ver detalles de conciliación | Muestra mes, año, valores comparados | ⬜ |

---

### E. Prueba 5: Registro Manual de Horas

**Objetivo:** Agregar horas manualmente (sin PDF).

| Acción | Esperado | Estado |
|--------|----------|--------|
| Tocar "Registrar horas" | Formulario con campos: tipo, cantidad, mes | ⬜ |
| Ingresar datos y guardar | Aparece en Historial | ⬜ |
| Editar registro | Cambios se persisten | ⬜ |
| Eliminar registro | Se marca como anulado (no borra) | ⬜ |

---

## Casos de Error Esperados (y Verificación)

### Error 1: PDF sin contraseña / contraseña incorrecta
- ✅ **Esperado:** Aparece mensaje "Contraseña incorrecta..." y se marca como `pendingPassword`
- ⬜ **Verificar:** Reintentar con contraseña correcta resuelve

### Error 2: Gmail no conecta (OAuth mal configurado)
- ✅ **Esperado:** Mensaje claro indicando package, SHA-1 y Client ID
- ⬜ **Verificar:** Seguir instrucciones y reintentar conecta OK

### Error 3: PDF con período no detectado
- ✅ **Esperado:** App usa fecha del correo o fecha actual como fallback
- ⬜ **Verificar:** Logs en `flutter logs` muestran "Período no detectado"

### Error 4: Sincronización parcial
- ✅ **Esperado:** Mensaje desglosado (importados/procesados/pendientes/fallos)
- ⬜ **Verificar:** Reintentar sincronización procesa los pendientes

---

## Logs Importantes

Para capturar logs en tiempo real:
```bash
flutter logs
```

**Buscar estos patrones para validar correcciones:**

```
# Error 1: Validación de excepciones Gmail
✅ "Error al conectar con Gmail: ..."
✅ "GmailAuthService.signIn failed:"

# Error 2: Validación de contraseña
✅ "Contraseña incorrecta o PDF protegido"
✅ "_findPeriod: Detectado período:"

# Error 3: Persistencia al reabrir
✅ "GmailSyncState gmailPrefsLoaded: true"

# Error 4: Logs de parsing
✅ "_findPeriod: Detectado por nombre de mes:"
✅ "ADVERTENCIA: No se detectaron horas en el texto"
```

---

## Checklist Final

Antes de considerar la app lista para producción:

- [ ] Navegación sin crashes
- [ ] PDF local importa y procesa correctamente
- [ ] Gmail conecta y sincroniza (si OAuth está OK)
- [ ] Contraseña se guarda y persiste
- [ ] Remitente se carga al reabrir app
- [ ] Período se detecta correctamente en PDFs
- [ ] Horas adeudadas/pagadas se extraen con precisión
- [ ] Conciliación muestra diferencias cuando existen
- [ ] Errores muestran mensajes claros (no "Exception" genérico)
- [ ] Logs ayudan a debuggear problemas

---

## Próximos Pasos (Post-Pruebas)

1. **Documentar issues encontrados:** Crear PRs o issues con descripción clara
2. **Generar APK release:** Cuando esté lista, compilar versión signada
3. **Distribuir:** Subir a Google Play Console o distribuir manual
4. **Monitoreo en backend:** Revisar logs en servidor si hay sincronización SaaS

---

**Última actualización:** 2026-09-09  
**Versión APK:** `app-debug.apk` (commit: f46709c)
