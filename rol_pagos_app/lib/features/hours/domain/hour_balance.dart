enum HourBalanceStatus {
  pending('Pendiente'),
  paid('Pagado'),
  overtime('A favor');

  const HourBalanceStatus(this.label);

  final String label;
}

class HourBalanceResult {
  const HourBalanceResult({
    required this.totalDebtHours,
    required this.totalPaidHours,
    required this.pendingHours,
    required this.overtimeHours,
    required this.status,
  });

  final double totalDebtHours;
  final double totalPaidHours;
  final double pendingHours;
  final double overtimeHours;
  final HourBalanceStatus status;
}

class HourBalance {
  const HourBalance({
    required this.id,
    required this.year,
    required this.month,
    required this.totalDebtHours,
    required this.totalPaidEquivalentHours,
    required this.pendingHours,
    required this.overtimeHours,
    required this.status,
    required this.calculatedAt,
  });

  final String id;
  final int year;
  final int month;
  final double totalDebtHours;
  final double totalPaidEquivalentHours;
  final double pendingHours;
  final double overtimeHours;
  final HourBalanceStatus status;
  final DateTime calculatedAt;
}
