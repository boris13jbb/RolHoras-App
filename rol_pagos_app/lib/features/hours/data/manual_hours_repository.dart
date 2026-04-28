import 'package:drift/drift.dart';

import '../../../data/local/app_database.dart';
import '../application/hour_calculation_service.dart';
import '../domain/hour_balance.dart';
import '../domain/hour_payment.dart';

class ManualHoursRepository {
  ManualHoursRepository({
    required AppDatabase db,
    HourCalculationService? calculationService,
  }) : _db = db,
       _calculationService =
           calculationService ?? const HourCalculationService();

  final AppDatabase _db;
  final HourCalculationService _calculationService;

  Stream<List<HourPayment>> watchPaymentsForMonth({
    required int year,
    required int month,
  }) {
    return _db.hourPaymentsDao
        .watchPaymentsForMonth(year: year, month: month)
        .map(_mapPayments);
  }

  Stream<HourBalanceResult> watchBalanceForMonth({
    required int year,
    required int month,
  }) {
    return _db.hourBalancesDao
        .watchBalanceForMonth(year: year, month: month)
        .map((row) => _mapBalanceRow(row, year: year, month: month));
  }

  Future<void> updateDebtHours({
    required int year,
    required int month,
    required double totalDebtHours,
  }) async {
    final sanitizedDebt = totalDebtHours < 0 ? 0.0 : totalDebtHours;
    await _recalculateAndUpsertBalance(
      year: year,
      month: month,
      debt: sanitizedDebt,
    );
  }

  Future<void> addPayment({
    required DateTime date,
    required double hours,
    required double percentage,
    String? observation,
  }) async {
    final equivalentHours = _calculationService.calculateEquivalentHours(
      hours: hours,
      percentage: percentage,
    );
    final now = DateTime.now();

    final payment = HourPaymentsTableCompanion.insert(
      id: now.microsecondsSinceEpoch.toString(),
      dateMillis: date.millisecondsSinceEpoch,
      hours: hours,
      percentage: percentage,
      equivalentHours: equivalentHours,
      observation: Value(
        observation?.trim().isEmpty ?? true ? null : observation!.trim(),
      ),
      payrollMonth: date.month,
      payrollYear: date.year,
      createdAtMillis: now.millisecondsSinceEpoch,
      updatedAtMillis: const Value.absent(),
    );

    await _db.hourPaymentsDao.upsertPayment(payment);

    final existingDebt = await _getDebtFromBalanceOrDefault(
      year: date.year,
      month: date.month,
    );
    await _recalculateAndUpsertBalance(
      year: date.year,
      month: date.month,
      debt: existingDebt,
    );
  }

  Future<void> updatePayment({
    required String id,
    required DateTime date,
    required double hours,
    required double percentage,
    String? observation,
  }) async {
    final existing = await _db.hourPaymentsDao.getPaymentById(id);
    if (existing == null) {
      throw StateError('No se encontró el pago a actualizar.');
    }

    final equivalentHours = _calculationService.calculateEquivalentHours(
      hours: hours,
      percentage: percentage,
    );
    final now = DateTime.now();

    final updated = HourPaymentsTableCompanion.insert(
      id: id,
      dateMillis: date.millisecondsSinceEpoch,
      hours: hours,
      percentage: percentage,
      equivalentHours: equivalentHours,
      observation: Value(
        observation?.trim().isEmpty ?? true ? null : observation!.trim(),
      ),
      payrollMonth: date.month,
      payrollYear: date.year,
      createdAtMillis: existing.createdAtMillis,
      updatedAtMillis: Value(now.millisecondsSinceEpoch),
    );

    await _db.hourPaymentsDao.upsertPayment(updated);

    // Recalcular balances (si el pago cambió de mes/año, recalcular ambos).
    final monthsToRecalc = <({int year, int month})>{
      (year: existing.payrollYear, month: existing.payrollMonth),
      (year: date.year, month: date.month),
    };

    for (final ym in monthsToRecalc) {
      final debt = await _getDebtFromBalanceOrDefault(year: ym.year, month: ym.month);
      await _recalculateAndUpsertBalance(year: ym.year, month: ym.month, debt: debt);
    }
  }

  Future<void> deletePayment({
    required String id,
  }) async {
    final existing = await _db.hourPaymentsDao.getPaymentById(id);
    if (existing == null) {
      return;
    }

    await _db.hourPaymentsDao.deletePaymentById(id);

    final debt = await _getDebtFromBalanceOrDefault(
      year: existing.payrollYear,
      month: existing.payrollMonth,
    );
    await _recalculateAndUpsertBalance(
      year: existing.payrollYear,
      month: existing.payrollMonth,
      debt: debt,
    );
  }

  Future<double> _getDebtFromBalanceOrDefault({
    required int year,
    required int month,
  }) async {
    final row = await _db.hourBalancesDao
        .watchBalanceForMonth(year: year, month: month)
        .first;
    return row?.totalDebtHours ?? 0.0;
  }

  Future<void> _recalculateAndUpsertBalance({
    required int year,
    required int month,
    required double debt,
  }) async {
    final payments = await _db.hourPaymentsDao.getPaymentsForMonth(
      year: year,
      month: month,
    );

    final result = _calculationService.calculateBalance(
      totalDebtHours: debt,
      paidEquivalentHours: [for (final p in payments) p.equivalentHours],
    );

    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    await _db.hourBalancesDao.upsertBalance(
      HourBalancesTableCompanion.insert(
        year: year,
        month: month,
        totalDebtHours: result.totalDebtHours,
        totalPaidEquivalentHours: result.totalPaidHours,
        pendingHours: result.pendingHours,
        overtimeHours: result.overtimeHours,
        status: result.status.name,
        calculatedAtMillis: nowMillis,
      ),
    );
  }

  List<HourPayment> _mapPayments(List<HourPaymentsTableData> rows) {
    return [
      for (final row in rows)
        HourPayment(
          id: row.id,
          date: DateTime.fromMillisecondsSinceEpoch(row.dateMillis),
          hours: row.hours,
          percentage: row.percentage,
          equivalentHours: row.equivalentHours,
          observation: row.observation,
          payrollMonth: row.payrollMonth,
          payrollYear: row.payrollYear,
          createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMillis),
          updatedAt: row.updatedAtMillis == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(row.updatedAtMillis!),
        ),
    ];
  }

  HourBalanceResult _mapBalanceRow(
    HourBalancesTableData? row, {
    required int year,
    required int month,
  }) {
    if (row == null) {
      return _calculationService.calculateBalance(
        totalDebtHours: 0,
        paidEquivalentHours: const [],
      );
    }

    return HourBalanceResult(
      totalDebtHours: row.totalDebtHours,
      totalPaidHours: row.totalPaidEquivalentHours,
      pendingHours: row.pendingHours,
      overtimeHours: row.overtimeHours,
      status: HourBalanceStatus.values.byName(row.status),
    );
  }
}
