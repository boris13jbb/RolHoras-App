import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hours/application/manual_hours_controller.dart';
import 'dashboard_summary.dart';

final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final balanceAsync = ref.watch(balanceForCurrentMonthProvider);
  final paymentsAsync = ref.watch(paymentsForCurrentMonthProvider);

  if (balanceAsync.isLoading || paymentsAsync.isLoading) {
    return const AsyncLoading();
  }

  final balance = balanceAsync.maybeWhen(data: (v) => v, orElse: () => null);
  final payments = paymentsAsync.maybeWhen(data: (v) => v, orElse: () => null);

  if (balance == null || payments == null) {
    return AsyncError(
      'No se pudo cargar el balance o los pagos.',
      StackTrace.current,
    );
  }

  return AsyncData(buildDashboardSummary(balance: balance, payments: payments));
});
