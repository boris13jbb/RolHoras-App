import '../domain/hour_balance.dart';
import '../domain/hour_payment.dart';

class ManualHoursState {
  const ManualHoursState({
    required this.totalDebtHours,
    required this.payments,
    required this.balance,
  });

  factory ManualHoursState.initial(HourBalanceResult balance) {
    return ManualHoursState(
      totalDebtHours: 0,
      payments: const [],
      balance: balance,
    );
  }

  final double totalDebtHours;
  final List<HourPayment> payments;
  final HourBalanceResult balance;

  ManualHoursState copyWith({
    double? totalDebtHours,
    List<HourPayment>? payments,
    HourBalanceResult? balance,
  }) {
    return ManualHoursState(
      totalDebtHours: totalDebtHours ?? this.totalDebtHours,
      payments: payments ?? this.payments,
      balance: balance ?? this.balance,
    );
  }
}
