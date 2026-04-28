import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_database_provider.dart';
import '../../../core/utils/year_month.dart';
import '../data/manual_hours_repository.dart';
import '../domain/hour_balance.dart';
import '../domain/hour_payment.dart';

final currentYearMonthProvider = Provider<YearMonth>((ref) {
  return YearMonth.fromDate(DateTime.now());
});

final manualHoursRepositoryProvider = Provider<ManualHoursRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ManualHoursRepository(db: db);
});

final paymentsForCurrentMonthProvider = StreamProvider<List<HourPayment>>((
  ref,
) {
  final ym = ref.watch(currentYearMonthProvider);
  final repo = ref.watch(manualHoursRepositoryProvider);
  return repo.watchPaymentsForMonth(year: ym.year, month: ym.month);
});

final balanceForCurrentMonthProvider = StreamProvider<HourBalanceResult>((ref) {
  final ym = ref.watch(currentYearMonthProvider);
  final repo = ref.watch(manualHoursRepositoryProvider);
  return repo.watchBalanceForMonth(year: ym.year, month: ym.month);
});

final balanceForMonthProvider =
    StreamProvider.family<HourBalanceResult, YearMonth>((ref, ym) {
  final repo = ref.watch(manualHoursRepositoryProvider);
  return repo.watchBalanceForMonth(year: ym.year, month: ym.month);
});

class ManualHoursController {
  const ManualHoursController(this._ref);

  final Ref _ref;

  Future<void> updateDebtHours(double totalDebtHours) async {
    final ym = _ref.read(currentYearMonthProvider);
    await _ref
        .read(manualHoursRepositoryProvider)
        .updateDebtHours(
          year: ym.year,
          month: ym.month,
          totalDebtHours: totalDebtHours,
        );
  }

  Future<void> addPayment({
    required DateTime date,
    required double hours,
    required double percentage,
    String? observation,
  }) async {
    await _ref
        .read(manualHoursRepositoryProvider)
        .addPayment(
          date: date,
          hours: hours,
          percentage: percentage,
          observation: observation,
        );
  }

  Future<void> updatePayment({
    required String id,
    required DateTime date,
    required double hours,
    required double percentage,
    String? observation,
  }) async {
    await _ref.read(manualHoursRepositoryProvider).updatePayment(
          id: id,
          date: date,
          hours: hours,
          percentage: percentage,
          observation: observation,
        );
  }

  Future<void> deletePayment({
    required String id,
  }) async {
    await _ref.read(manualHoursRepositoryProvider).deletePayment(id: id);
  }
}

final manualHoursControllerProvider = Provider<ManualHoursController>((ref) {
  return ManualHoursController(ref);
});
