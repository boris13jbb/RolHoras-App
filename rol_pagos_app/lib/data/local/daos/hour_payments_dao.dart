import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/hour_payments_table.dart';

part 'hour_payments_dao.g.dart';

@DriftAccessor(tables: [HourPaymentsTable])
class HourPaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$HourPaymentsDaoMixin {
  HourPaymentsDao(super.db);

  Stream<List<HourPaymentsTableData>> watchPaymentsForMonth({
    required int year,
    required int month,
  }) {
    return (select(hourPaymentsTable)
          ..where(
            (tbl) =>
                tbl.payrollYear.equals(year) & tbl.payrollMonth.equals(month),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.dateMillis)]))
        .watch();
  }

  Future<List<HourPaymentsTableData>> getPaymentsForMonth({
    required int year,
    required int month,
  }) {
    return (select(hourPaymentsTable)..where(
          (tbl) =>
              tbl.payrollYear.equals(year) & tbl.payrollMonth.equals(month),
        ))
        .get();
  }

  Future<void> upsertPayment(HourPaymentsTableCompanion entry) async {
    await into(hourPaymentsTable).insertOnConflictUpdate(entry);
  }

  Future<HourPaymentsTableData?> getPaymentById(String id) {
    return (select(hourPaymentsTable)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> deletePaymentById(String id) {
    return (delete(hourPaymentsTable)..where((tbl) => tbl.id.equals(id))).go();
  }
}
