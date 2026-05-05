import 'package:flutter_test/flutter_test.dart';
import 'package:rol_pagos_app/features/pdf_reader/application/payroll_pdf_text_parser.dart';

void main() {
  group('PayrollPdfTextParser', () {
    const vicunhaSnippet = '''
NOTAS HORAS
-496.45	HORAS SALDO ANTERIOR
128.16	HORAS COMPENSANDAS
-368.29	SALDO ACTUAL
823.08 481.26	TOTALES ====== > A Recibir ===> 341.82
RECIBI EN CONFORMIDAD
''';

    test('V02360: NOTAS HORAS con número antes de la etiqueta', () {
      const parser = PayrollPdfTextParser();
      final r = parser.parse(vicunhaSnippet);

      expect(r.debtHours, closeTo(-496.45, 0.01));
      expect(r.paidHours, closeTo(128.16, 0.01));
      expect(r.pendingHours, closeTo(-368.29, 0.01));
    });

    test('Etiqueta después del número en una sola línea (normalizado)', () {
      const parser = PayrollPdfTextParser();
      final r = parser.parse(
        '-496.45 horas saldo anterior 128.16 horas compensandas -368.29 saldo actual',
      );

      expect(r.debtHours, closeTo(-496.45, 0.01));
      expect(r.paidHours, closeTo(128.16, 0.01));
      expect(r.pendingHours, closeTo(-368.29, 0.01));
    });

    test('No mezcla 823.08 de TOTALES dentro del bloque NOTAS', () {
      const parser = PayrollPdfTextParser();
      final r = parser.parse(vicunhaSnippet);

      expect(r.pendingHours, isNot(closeTo(823.08, 0.1)));
      expect(r.paidHours, isNot(closeTo(368.29, 0.1)));
    });
  });
}
