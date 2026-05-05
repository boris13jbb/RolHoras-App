import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/year_month.dart';
import '../../hours/application/manual_hours_controller.dart';
import '../../hours/domain/hour_balance.dart';
import '../domain/payroll_document.dart';
import 'payroll_providers.dart';

/// "Último rol" para el usuario: por **periodo del rol** (año/mes).
///
/// Si hay empate en periodo, se prioriza el más reciente por fecha de proceso o
/// importación.
PayrollDocument? pickLatestPayrollDocument(List<PayrollDocument> list) {
  if (list.isEmpty) return null;
  final sorted = [...list];
  sorted.sort((a, b) {
    // 1) Periodo (año/mes) descendente.
    final byYear = b.year.compareTo(a.year);
    if (byYear != 0) return byYear;
    final byMonth = b.month.compareTo(a.month);
    if (byMonth != 0) return byMonth;

    // 2) Tie-break: fecha de proceso/importación descendente.
    final ta = a.processedAt ?? a.importedAt;
    final tb = b.processedAt ?? b.importedAt;
    return tb.compareTo(ta);
  });
  return sorted.first;
}

class LatestPayrollComparison {
  const LatestPayrollComparison({
    required this.payroll,
    required this.balance,
    required this.yearMonth,
  });

  final PayrollDocument payroll;
  final HourBalanceResult balance;
  final YearMonth yearMonth;
}

final latestPayrollComparisonProvider =
    Provider<AsyncValue<LatestPayrollComparison?>>((ref) {
      final payrollsAsync = ref.watch(payrollDocumentsProvider);

      return payrollsAsync.when(
        data: (list) {
          final payroll = pickLatestPayrollDocument(list);
          if (payroll == null) {
            return const AsyncData(null);
          }
          final ym = YearMonth(year: payroll.year, month: payroll.month);
          final balanceAsync = ref.watch(balanceForMonthProvider(ym));
          return balanceAsync.when(
            data: (balance) => AsyncData(
              LatestPayrollComparison(
                payroll: payroll,
                balance: balance,
                yearMonth: ym,
              ),
            ),
            loading: () => const AsyncLoading(),
            error: AsyncError.new,
          );
        },
        loading: () => const AsyncLoading(),
        error: AsyncError.new,
      );
    });
