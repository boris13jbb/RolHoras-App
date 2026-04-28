import '../../hours/domain/hour_balance.dart';
import '../../hours/domain/hour_payment.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.balance,
    required this.paymentsCount,
    required this.equivalentByPercentage,
    required this.lastPayment,
  });

  final HourBalanceResult balance;
  final int paymentsCount;

  /// Mapa: porcentaje -> horas equivalentes acumuladas en el mes.
  final Map<double, double> equivalentByPercentage;

  final HourPayment? lastPayment;
}

DashboardSummary buildDashboardSummary({
  required HourBalanceResult balance,
  required List<HourPayment> payments,
}) {
  final map = <double, double>{};
  for (final payment in payments) {
    map.update(
      payment.percentage,
      (value) => value + payment.equivalentHours,
      ifAbsent: () => payment.equivalentHours,
    );
  }

  return DashboardSummary(
    balance: balance,
    paymentsCount: payments.length,
    equivalentByPercentage: map,
    lastPayment: payments.isEmpty ? null : payments.first,
  );
}
