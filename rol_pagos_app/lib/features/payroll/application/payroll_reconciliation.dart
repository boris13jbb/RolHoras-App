import '../../hours/domain/hour_balance.dart';
import '../domain/payroll_document.dart';

/// Umbral para considerar coincidentes PDF vs app en conciliación.
const double payrollReconciliationToleranceHours = 0.1;

/// Filas estándar: negocio Vicunha / NOTAS HORAS (deuda vs compensadas vs pendiente).
List<PayrollReconciliationRow> buildPayrollReconciliationRows({
  required PayrollDocument payroll,
  required HourBalanceResult balance,
}) {
  return [
    PayrollReconciliationRow(
      concept: 'Saldo anterior',
      pdfField: payroll.detectedDebtHours,
      appValue: balance.totalDebtHours,
    ),
    PayrollReconciliationRow(
      concept: 'Horas compensadas (a favor)',
      pdfField: payroll.detectedPaidHours,
      appValue: balance.totalPaidHours,
    ),
    PayrollReconciliationRow(
      concept: 'Saldo actual',
      subtitle: 'Deuda tras compensar (equiv. pendiente en app)',
      pdfField: payroll.detectedPendingHours,
      appValue: balance.pendingHours,
    ),
  ];
}

/// Mismos criterios que el diálogo de Historial (magnitudes en PDF con signo).
List<String> payrollReconciliationIssues(
  PayrollDocument payroll,
  HourBalanceResult balance,
) {
  final issues = <String>[];

  void compareMagnitudes(String label, double? pdfRaw, double appValue) {
    if (pdfRaw == null) return;
    final pdfMag = pdfRaw.abs();
    final diff = (pdfMag - appValue).abs();
    if (diff > payrollReconciliationToleranceHours) {
      issues.add(
        '$label: PDF ${pdfMag.toStringAsFixed(1)}h vs App ${appValue.toStringAsFixed(1)}h (Δ ${diff.toStringAsFixed(1)}h)',
      );
    }
  }

  compareMagnitudes(
    'Saldo anterior (horas adeudadas)',
    payroll.detectedDebtHours,
    balance.totalDebtHours,
  );
  compareMagnitudes(
    'Horas compensadas (a favor; equiv. pagos en app)',
    payroll.detectedPaidHours,
    balance.totalPaidHours,
  );
  compareMagnitudes(
    'Saldo actual (horas adeudadas tras compensar; equiv. pendiente en app)',
    payroll.detectedPendingHours,
    balance.pendingHours,
  );

  return issues;
}

bool payrollHasComparableDetections(PayrollDocument p) =>
    p.detectedDebtHours != null ||
    p.detectedPaidHours != null ||
    p.detectedPendingHours != null;

class PayrollReconciliationRow {
  const PayrollReconciliationRow({
    required this.concept,
    this.subtitle,
    required this.pdfField,
    required this.appValue,
  });

  final String concept;
  final String? subtitle;
  final double? pdfField;
  final double appValue;

  /// Valor PDF mostrado (misma regla que conciliación: magnitud).
  String get pdfDisplay =>
      pdfField == null ? '—' : pdfField!.abs().toStringAsFixed(1);

  String get appDisplay => appValue.toStringAsFixed(1);

  bool get hasPdfValue => pdfField != null;

  bool get matches {
    if (pdfField == null) return true;
    final pdfMag = pdfField!.abs();
    return (pdfMag - appValue).abs() <= payrollReconciliationToleranceHours;
  }

  double? get deltaHours {
    if (pdfField == null) return null;
    return (pdfField!.abs() - appValue).abs();
  }
}
