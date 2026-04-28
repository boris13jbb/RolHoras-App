class PayrollPdfParseResult {
  const PayrollPdfParseResult({
    this.debtHours,
    this.paidHours,
    this.pendingHours,
  });

  final double? debtHours;
  final double? paidHours;
  final double? pendingHours;
}

class PayrollPdfTextParser {
  const PayrollPdfTextParser();

  /// Parser heurístico: intenta encontrar números cerca de palabras clave.
  /// Nunca inventa datos: si no encuentra, devuelve null.
  PayrollPdfParseResult parse(String text) {
    final normalized = _normalize(text);

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

    final pending = _findNumberNear(normalized, [
      RegExp(r'horas\s+pendientes'),
      RegExp(r'saldo\s+pendiente'),
      RegExp(r'saldo\s+actual'),
    ]);

    return PayrollPdfParseResult(
      debtHours: debt,
      paidHours: paid,
      pendingHours: pending,
    );
  }

  String _normalize(String input) {
    return input
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .toLowerCase();
  }

  double? _findNumberNear(String text, List<RegExp> keywords) {
    for (final keyword in keywords) {
      final match = keyword.firstMatch(text);
      if (match == null) continue;

      final start = match.end;
      final windowEnd = (start + 120).clamp(0, text.length);
      final window = text.substring(start, windowEnd);

      final num = _extractFirstNumber(window);
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
}
