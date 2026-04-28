# Cálculo de horas en RolPagosApp y relación con el contrato colectivo

Este documento explica **cómo calcula la aplicación** las horas equivalentes y el saldo mensual, y lo contrasta con las **reglas del contrato / política laboral** (según las páginas y cláusulas que has compartido en imágenes). Sirve para validar qué está **correctamente implementado a nivel de fórmula** y qué depende de **criterio manual** o **fases futuras**.

---

## 1. Resumen ejecutivo

| Aspecto | En la app hoy | En el contrato (síntesis) |
|--------|----------------|---------------------------|
| **Equivalencia “pago → horas equivalentes”** | `horas × (porcentaje / 100)` donde el porcentaje representa un **multiplicador** (100% = ×1, 200% = ×2, 130% = ×1,30, etc.) | Hay **varias reglas** (días de descanso = 2×, recargos adicionales 20%/25% según franja horaria, equivalencias 1→1,30, 1→1,5, trabajo en vacaciones al 100%, etc.) |
| **Deuda total del mes** | El usuario la **ingresa manualmente** en el dashboard (“Actualizar deuda”), alineada conceptualmente con “horas adeudadas / saldo” del rol | El rol puede mostrar **saldo anterior**, **horas compensadas**, **saldo actual**; la deuda “oficial” viene del **empleador y del acumulado por compensar** |
| **Saldo después de pagos** | `deuda − suma(horas equivalentes de cada pago)`; si sobra deuda → pendiente; si sobra pago → “a favor” | Lógica de negocio similar a un **ledger**, pero el contrato añade **límites, excepciones y liqui­daciones** no modeladas en la app |
| **Artículos del contrato (fechas, turnos, vacaciones, bonos de 6 sueldos, 70% en finiquito)** | **No** hay motor de reglas por fecha, turno ni expediente legal | Requieren **reglas explícitas** y, en muchos casos, **datos que hoy no introduce el usuario** (calendario de jornadas, avisos de 5/7 días, etc.) |

**Conclusión:** La implementación actual es **matemáticamente consistente** para el modelo elegido (multiplicador sobre horas registradas + saldo simple). Es una **herramienta de seguimiento manual** encajada con varias **etiquetas inspiradas** en el contrato, pero **no sustituye** la liquidación oficial del empleador ni reproduce **todas** las cláusulas del texto legal.

---

## 2. Qué hace el código (fuente de verdad)

### 2.1. Horas equivalentes de un pago manual

Archivo: `lib/features/hours/application/hour_calculation_service.dart`

```text
equivalentHours = hours × (percentage / 100)
```

- `hours`: cantidad de horas que el usuario declara para ese movimiento.
- `percentage`: no es solo “porcentaje legal” genérico; en la UI se usa como **selector de multiplicador**:
  - `100` → ×1,00  
  - `120` → ×1,20 (etiquetado como recargo 20%)  
  - `125` → ×1,25  
  - `130` → ×1,30 (etiquetado como equivalencia 1→1,30)  
  - `200` → ×2,00 (descanso / 2 días compensados en el lenguaje de la UI)  
  - `240`, `250` → combinaciones ×2,4 y ×2,5 según la opción elegida  
  - `0` + campo “Personalizado” → el usuario ingresa el porcentaje numérico.

Los casos numéricos están cubiertos en tests en `test/widget_test.dart` (“calcula equivalencias según contrato (20%, 25%, 1→1.30 y 2 días)”).

### 2.2. Balance del mes

Mismo servicio:

```text
totalPaid = suma de equivalentHours de todos los pagos del mes
difference = totalDebtHours - totalPaid
```

- Si `difference > 0` → **pendiente** (aún falta “pagar” en horas equivalentes).  
- Si `difference == 0` → **cuadrado** (etiqueta “pagado” en términos de este modelo).  
- Si `difference < 0` → **a favor** (en la app, `overtimeHours = |difference|`; el nombre histórico “overtime” aquí significa “horas a favor / saldo positivo de compensación” en sentido de **diferencia a favor del trabajador** frente a la deuda declarada).

**Importante:** `totalDebtHours` en la app es el valor que el usuario **configura** como “deuda manual del mes” (pantalla Dashboard). No se recalcula automáticamente desde el PDF en todos los flujos; el PDF/rol se usa en otra parte del sistema para **detección heurística** y **conciliación** cuando corresponde.

---

## 3. Relación con el contrato (según documentos compartidos)

A continuación se resumen **ideas del contrato** que aparecen en las imágenes que enviaste, y cómo se relacionan (o no) con la app.

### 3.1. Días de descanso y equivalencias “1 día → 2 días compensados”

En el contrato (p. ej. fuerza mayor / paralización) se indica que los días de descanso normal pueden equivaler a **2 días compensados** en ciertos supuestos.

- **En la app:** existe la opción de UI **“Descanso: 2 días compensados (×2.00)”**, que aplica el multiplicador **200%** sobre las **horas** que tú introduzcas. Eso modela “duplicar el efecto en horas equivalentes”, **asumiendo** que ya convertiste el “día” en “horas” a tu criterio (p. ej. 8 h × 2 = 16 h equivalentes).

**Límite del modelo:** el contrato habla a veces de **días** y de **procedimientos** (comité, registros, acumulado por compensar). La app no distingue “día calendario” vs “8,4 h” salvo lo que tú reflejes en el campo `hours`.

### 3.2. Recargos adicionales 20% y 25% (franjas 06:00–19:00 y 19:00–06:00)

Cláusulas de **jornadas extraordinarias obligatorias** en fechas concretas o sábados/domingos con avisos: recargos **adicionales** del **20%** o **25%** según franja.

- **En la app:** hay opciones **“Recargo 20% (×1,20)”** y **“Recargo 25% (×1,25)”** como multiplicadores **sobre las horas** del registro.  
- **Diferencia con el contrato:** en el convenio, esos recargos suelen ser **adicionales** a la base legal/contractual; aquí se modela un **único** factor `×1,20` o `×1,25` **por movimiento**, sin desglosar “base + adicional + legal”. Si necesitas apilar recargos, hoy debes **condensar** el resultado en un solo multiplicador (p. ej. vía “Personalizado”) o dividir en varios renglones con criterio propio.

### 3.3. Equivalencia 1 → 1,30 (p. ej. descuento de “6 sueldos diarios” u operaciones análogas en el art.)

El contrato menciona, en contextos de compensación de saldo, una equivalencia del tipo **1 → 1,30** (texto e ilustraciones que compartiste).

- **En la app:** opción **“Equivalencia 1→1,30 (×1,30)”** → `percentage = 130` → `horas × 1,30`.  
- Esto **coincide** con la intención matemática “cada hora de este tipo cuenta 1,30 h equivalentes” **si** las `hours` que ingresas son las correctas según el procedimiento de compensación.

### 3.4. Otras equivalencias (1,5; vacaciones con 100% recargo; 70% en finiquito; bono 6 sueldos en agosto; etc.)

En las mismas imágenes aparecen, entre otras:

- **1 → 1,5** (extensiones o casos concretos de compensación en otros turnos).  
- Trabajo en **días de vacaciones** considerado con **100% de recargo** (en la práctica, factor **×2** sobre el valor de esas horas, con reglas de liquidación al mes siguiente).  
- **70%** del valor al liquidar en retiro.  
- **Bono** por días de descanso suprimidos (p. ej. 6 jornales en liquidación de agosto), que es un concepto **monetario** más que de “horas” directas.

**En la app:** no hay módulo que, por calendario, aplique 20/25% según **fecha** o **turno**; no hay tampoco el flujo de “pago al mes siguiente” de vacaciones; ni el 70% de finiquito; ni el cálculo automático del bono de 6 sueldos.  
Todo eso quedaría en **fases de producto** (nuevas pantallas, parámetros, o integración con datos del rol/RRHH).

### 3.5. Cómo se ve en el “rol de pagos” (PDF) que compartiste

En PDFs reales, el bloque “NOTAS HORAS” incluye, por ejemplo:

- `HORAS SALDO ANTERIOR` (puede ser negativo)  
- `HORAS COMPENSADAS` o variantes (p. ej. “HORAS COMPENSANDAS”) o `HORAS POR COMPENSAR` (según el mes)  
- `SALDO ACTUAL` (negativo = sigues debiendo a favor de la “compensación de horas” en el lenguaje del empleador, o positivo según política; la app hace **conciliación** entre valores detectados y el balance local cuando el PDF se procesa).

Eso **complementa** al cálculo manual, pero no reemplaza la definición de “deuda” del dashboard salvo que alinees ambos a mano o por importación progresiva de reglas.

---

## 4. ¿Está “bien implementado” el cálculo?

### 4.1. Lo que sí está bien (respecto al diseño de la app)

- La **fórmula** `equivalentHours = hours × (percentage/100)` es **coherente** y **reproducible**.  
- El **balance** `deuda − total pagado (equivalente)` es un modelo **lógico** de libro de deuda a compensar en **horas equivalentes**, alineable con un seguimiento personal.  
- Los **tests unitarios** validan:
  - suma de varios pagos con distintos porcentajes,  
  - transición a “a favor” cuando el equivalente paga de más,  
  - multiplicadores 120, 125, 130, 200, 250 asociados a las etiquetas de contrato usadas en la app.

### 4.2. Lo que no es “implementación del contrato completo”

- **No** se modelan todas las cláusulas: fechas, turnos, preavisos, apilación de recargos, bono de agosto, 70% de finiquito, etc.  
- El **“porcentaje”** de la app es un **simplificador**: conviene verlo como **“factor de conversión a horas equivalentes de compensación”** elegido por el usuario según el caso, no como una simulación automática de la planilla de RRHH.  
- La **deuda** del mes y las **horas** de cada línea requieren **criterio** o datos externos (rol, comité, acumulado).

**Por tanto:** el cálculo **interno** de la app es **correcto para su modelo**; el contrato exige además un **criterio de negocio** (y a menudo datos) que **hoy** introduces tú. La app **apoya** el seguimiento; **no** certifica conformidad con el convenio al 100% sin esa capa de reglas y datos.

---

## 5. Cómo usar la app alineada al contrato (recomendación práctica)

1. **Fija** la deuda del mes (dashboard) a partir de lo que consideres **saldo a compensar** (puede acercarse al “SALDO ACTUAL / saldo anterior” del rol, según tu regla de interpretación).  
2. Cada evento (descanso compensado, recargo, equivalencia 1,30, etc.): elige en el desplegable el **multiplicador** que corresponda a **ese** tramo de horas, o usa **Personalizado** si el convenio pide un factor no listado.  
3. Revisa el **Historial** y la **conciliación** con el PDF (cuando esté habilitada) para ver si el rol y tu balance manual divergen.  
4. Si una cláusula pide **sumar** varios recargos, convierte a **un solo** factor equivalente o divide en **varias líneas** con factores distintos.

---

## 6. Próximos pasos de producto (si se quiere aproximarse al contrato con código)

- Catálogo de **preajustes** por artículo (1→1,5, ×2, ×1,3, apilamientos) con **nombres** del convenio.  
- Registro de **jornada** o **turno** para aplicar 20% vs 25% según franja, si el usuario informa la hora.  
- Vinculación de **deuda inicial** a importación de “NOTAS HORAS” del PDF.  
- Reglas para **acumulado** multimes y para **finiquito** (70%).

---

## 7. Archivos de referencia en el repositorio

| Archivo | Rol |
|--------|-----|
| `lib/features/hours/application/hour_calculation_service.dart` | Fórmulas de equivalente y balance |
| `lib/features/hours/presentation/hour_registration_screen.dart` | Etiquetas y valores `percentage` de la UI |
| `lib/features/hours/data/manual_hours_repository.dart` | Persistencia y recálculo de balance |
| `test/widget_test.dart` | Pruebas de equivalencias y saldo |
| `lib/features/pdf_reader/application/payroll_pdf_text_parser.dart` | Heurísticas de extracción de cifras del PDF (sujeto a formato del empleador) |

---

*Documento generado para acompañar la revisión del cálculo de horas y el contrato colectivo / políticas de Vicunha, según imágenes y PDFs aportados por el usuario. Si cambia el texto del convenio o el formato del rol, habrá que revisar heurísticas y etiquetas, no solo la fórmula `hours × (p/100)`.*
