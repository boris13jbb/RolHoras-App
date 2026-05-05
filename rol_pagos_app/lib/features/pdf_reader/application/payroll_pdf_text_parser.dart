class PayrollPdfParseResult {
  const PayrollPdfParseResult({
    this.debtHours,
    this.paidHours,
    this.pendingHours,
    this.periodYear,
    this.periodMonth,
  });

  final double? debtHours;
  final double? paidHours;
  final double? pendingHours;
  final int? periodYear;
  final int? periodMonth;
}

class PayrollPdfTextParser {
  const PayrollPdfTextParser();

  /// Parser heurístico: intenta encontrar números cerca de palabras clave.
  /// Nunca inventa datos: si no encuentra, devuelve null.
  PayrollPdfParseResult parse(String text) {
    final normalized = _normalize(text);

    final period = _findPeriod(normalized);

    // Vicunha / muchos roles: bloque "NOTAS HORAS" con columnas tipo
    // `-496.45  HORAS SALDO ANTERIOR` (el número va **antes** de la etiqueta).
    // El método antiguo solo buscaba números *después* del match y acababa
    // mezclando con "Monto Aportable" (823.08), saldo actual (-368.29), etc.
    final notas = _parseNotasHorasBlock(normalized);
    if (notas != null) {
      return PayrollPdfParseResult(
        debtHours: notas.debtHours,
        paidHours: notas.paidHours,
        pendingHours: notas.pendingHours,
        periodYear: period?.$1,
        periodMonth: period?.$2,
      );
    }

    final debt = _findNumberNear(normalized, [
      RegExp(r'saldo\s+de\s+horas'),
      RegExp(r'horas\s+saldo\s+anterior'),
      RegExp(r'saldo\s+anterior'),
      RegExp(r'horas\s+adeudadas'),
      RegExp(r'total\s+adeudado'),
      RegExp(r'deuda\s+de\s+horas'),
    ]);

    final paid = _findNumberNear(normalized, [
      RegExp(r'horas\s+pagadas'),
      RegExp(r'horas\s+compensadas'),
      // En algunos roles viene con typo ("compensandas") o variaciones.
      RegExp(r'horas\s+compensan\w+'),
      RegExp(r'total\s+pagado'),
    ]);

    // Saldo actual / pendiente en el PDF: deuda remanente (horas adeudadas), no
    // "horas a favor". Compensadas/pagadas se parsean aparte en [paid].
    final pending = _findNumberNear(normalized, [
      RegExp(r'horas\s+pendientes'),
      RegExp(r'saldo\s+pendiente'),
      RegExp(r'saldo\s+actual'),
    ]);

    return PayrollPdfParseResult(
      debtHours: debt,
      paidHours: paid,
      pendingHours: pending,
      periodYear: period?.$1,
      periodMonth: period?.$2,
    );
  }

  /// Extrae las tres magnitudes del bloque típico bajo "NOTAS HORAS", aceptando
  /// número antes o después de la etiqueta (layout en columnas).
  _NotasHorasParsed? _parseNotasHorasBlock(String normalized) {
    const anchor = 'notas horas';
    final anchorIdx = normalized.indexOf(anchor);
    if (anchorIdx < 0) return null;

    final start = anchorIdx + anchor.length;
    var end = normalized.length;
    final totalesIdx = normalized.indexOf('totales', start);
    if (totalesIdx > start) end = totalesIdx;
    final recibiIdx = normalized.indexOf('recibi', start);
    if (recibiIdx > start && recibiIdx < end) end = recibiIdx;

    final limit = start + 900;
    if (end > limit) end = limit;
    if (end <= start) return null;

    final window = normalized.substring(start, end);

    double? debt = _firstDoubleGroup(
      window,
      [
        // -496.45 horas saldo anterior
        RegExp(
          r'(-?\d{1,6}(?:[.,]\d{1,4})?)\s+horas\s+saldo\s+anterior\b',
        ),
        RegExp(
          r'\bhoras\s+saldo\s+anterior\b\s+(-?\d{1,6}(?:[.,]\d{1,4})?)',
        ),
      ],
    );

    double? paid = _firstDoubleGroup(
      window,
      [
        // 128.16 horas compensandas (typo frecuente)
        RegExp(
          r'(-?\d{1,6}(?:[.,]\d{1,4})?)\s+horas\s+compens\w+',
        ),
        RegExp(
          r'\bhoras\s+compens\w+\s+(-?\d{1,6}(?:[.,]\d{1,4})?)',
        ),
      ],
    );

    double? pending = _firstDoubleGroup(
      window,
      [
        RegExp(
          r'(-?\d{1,6}(?:[.,]\d{1,4})?)\s+saldo\s+actual\b',
        ),
        RegExp(
          r'\bsaldo\s+actual\b\s+(-?\d{1,6}(?:[.,]\d{1,4})?)',
        ),
      ],
    );

    if (debt == null && paid == null && pending == null) return null;

    return _NotasHorasParsed(
      debtHours: debt,
      paidHours: paid,
      pendingHours: pending,
    );
  }

  double? _firstDoubleGroup(String window, List<RegExp> patterns) {
    for (final re in patterns) {
      final m = re.firstMatch(window);
      if (m == null) continue;
      final g = m.group(1);
      if (g == null) continue;
      final v = double.tryParse(g.replaceAll(',', '.'));
      if (v != null) return v;
    }
    return null;
  }

  String _normalize(String input) {
    return input
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .toLowerCase();
  }

  (int, int)? _findPeriod(String text) {
    // Prioridad 1: rango de fechas del rol, típico:
    // "Del: 1/3/2026 al 31/3/2026" (puede venir con o sin ":" y con espacios variables).
    // Esto es más robusto que depender del nombre del mes.
    final range = RegExp(
      r'(?:\bdel\b\s*:?\s*)(\d{1,2})\s*/\s*(\d{1,2})\s*/\s*(20\d{2})\s*(?:\bal\b)\s*(\d{1,2})\s*/\s*(\d{1,2})\s*/\s*(20\d{2})',
    ).firstMatch(text);
    if (range != null) {
      final m1 = int.tryParse(range.group(2) ?? '');
      final y1 = int.tryParse(range.group(3) ?? '');
      final m2 = int.tryParse(range.group(5) ?? '');
      final y2 = int.tryParse(range.group(6) ?? '');
      // Si ambos años coinciden, usamos ese año; si no, preferimos el inicio.
      final year = (y1 != null && y2 != null && y1 == y2) ? y1 : y1;
      final month = m1;
      if (year != null && month != null && month >= 1 && month <= 12) {
        return (year, month);
      }
      // Fallback a mes del final.
      if (y2 != null && m2 != null && m2 >= 1 && m2 <= 12) {
        return (y2, m2);
      }
    }

    // Variante con guiones: "Del 01-03-2026 al 31-03-2026"
    final rangeDash = RegExp(
      r'(?:\bdel\b\s*:?\s*)(\d{1,2})\s*-\s*(\d{1,2})\s*-\s*(20\d{2})\s*(?:\bal\b)\s*(\d{1,2})\s*-\s*(\d{1,2})\s*-\s*(20\d{2})',
    ).firstMatch(text);
    if (rangeDash != null) {
      final m1 = int.tryParse(rangeDash.group(2) ?? '');
      final y1 = int.tryParse(rangeDash.group(3) ?? '');
      final m2 = int.tryParse(rangeDash.group(5) ?? '');
      final y2 = int.tryParse(rangeDash.group(6) ?? '');
      final year = (y1 != null && y2 != null && y1 == y2) ? y1 : y1;
      final month = m1;
      if (year != null && month != null && month >= 1 && month <= 12) {
        return (year, month);
      }
      if (y2 != null && m2 != null && m2 >= 1 && m2 <= 12) {
        return (y2, m2);
      }
    }

    // Casos típicos (como el correo de ejemplo):
    // - "correspondiente al mes de Marzo del año 2026"
    // - "mes de marzo del año 2026"
    // - "marzo 2026"
    const monthMap = <String, int>{
      'enero': 1,
      'febrero': 2,
      'marzo': 3,
      'abril': 4,
      'mayo': 5,
      'junio': 6,
      'julio': 7,
      'agosto': 8,
      'septiembre': 9,
      'setiembre': 9,
      'octubre': 10,
      'noviembre': 11,
      'diciembre': 12,
    };

    final monthAlternation = monthMap.keys.join('|');
    final patterns = <RegExp>[
      RegExp(
        '(?:mes\\s+de\\s+)?($monthAlternation)\\s+del\\s+ano\\s+(20\\d{2})',
      ),
      RegExp(
        '(?:mes\\s+de\\s+)?($monthAlternation)\\s+del\\s+año\\s+(20\\d{2})',
      ),
      RegExp(
        '(?:mes\\s+de\\s+)?($monthAlternation)\\s+de\\s+(20\\d{2})',
      ),
      RegExp('($monthAlternation)\\s+(20\\d{2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final monthName = (match.group(1) ?? '').trim();
      final yearStr = (match.group(2) ?? '').trim();
      final month = monthMap[monthName];
      final year = int.tryParse(yearStr);
      if (month != null && year != null && month >= 1 && month <= 12) {
        return (year, month);
      }
    }
    return null;
  }

  double? _findNumberNear(String text, List<RegExp> keywords) {
    for (final keyword in keywords) {
      final match = keyword.firstMatch(text);
      if (match == null) continue;

      final afterStart = match.end;
      final afterEnd = (afterStart + 120).clamp(0, text.length);
      final after = text.substring(afterStart, afterEnd);

      final beforeStart = (match.start - 120).clamp(0, match.start);
      final before = text.substring(beforeStart, match.start);

      // Columna típica: importe antes de la etiqueta. Si miramos primero
      // *después*, en la siguiente línea suele estar otro número (ej. Vicunha).
      final num =
          _extractLastNumber(before) ?? _extractFirstNumber(after);
      if (num != null) return num;
    }
    return null;
  }

  double? _extractFirstNumber(String s) {
    // Captura: -496.45, 128.16, 10,5 (con signo opcional)
    final match = RegExp(r'(-?\d{1,6}([.,]\d{1,2})?)').firstMatch(s);
    if (match == null) return null;
    final raw = match.group(1)!.replaceAll(',', '.');
    return double.tryParse(raw);
  }

  /// Último número en el segmento (el más cercano a la etiqueta si va antes).
  double? _extractLastNumber(String s) {
    double? last;
    for (final m in RegExp(r'(-?\d{1,6}(?:[.,]\d{1,2})?)').allMatches(s)) {
      final v = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      if (v != null) last = v;
    }
    return last;
  }
}

class _NotasHorasParsed {
  const _NotasHorasParsed({
    required this.debtHours,
    required this.paidHours,
    required this.pendingHours,
  });

  final double? debtHours;
  final double? paidHours;
  final double? pendingHours;
}
