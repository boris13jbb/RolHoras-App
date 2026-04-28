import '../domain/hour_balance.dart';

class HourCalculationService {
  const HourCalculationService();

  double calculateEquivalentHours({
    required double hours,
    required double percentage,
  }) {
    return hours * (percentage / 100);
  }

  HourBalanceResult calculateBalance({
    required double totalDebtHours,
    required List<double> paidEquivalentHours,
  }) {
    final totalPaid = paidEquivalentHours.fold<double>(
      0,
      (previous, current) => previous + current,
    );

    final difference = totalDebtHours - totalPaid;

    if (difference > 0) {
      return HourBalanceResult(
        totalDebtHours: totalDebtHours,
        totalPaidHours: totalPaid,
        pendingHours: difference,
        overtimeHours: 0,
        status: HourBalanceStatus.pending,
      );
    }

    if (difference == 0) {
      return HourBalanceResult(
        totalDebtHours: totalDebtHours,
        totalPaidHours: totalPaid,
        pendingHours: 0,
        overtimeHours: 0,
        status: HourBalanceStatus.paid,
      );
    }

    return HourBalanceResult(
      totalDebtHours: totalDebtHours,
      totalPaidHours: totalPaid,
      pendingHours: 0,
      overtimeHours: difference.abs(),
      status: HourBalanceStatus.overtime,
    );
  }
}
