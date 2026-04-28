import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/hour_balances_table.dart';

part 'hour_balances_dao.g.dart';

@DriftAccessor(tables: [HourBalancesTable])
class HourBalancesDao extends DatabaseAccessor<AppDatabase>
    with _$HourBalancesDaoMixin {
  HourBalancesDao(super.db);

  Stream<HourBalancesTableData?> watchBalanceForMonth({
    required int year,
    required int month,
  }) {
    return (select(hourBalancesTable)
          ..where((tbl) => tbl.year.equals(year) & tbl.month.equals(month)))
        .watchSingleOrNull();
  }

  Future<void> upsertBalance(HourBalancesTableCompanion entry) async {
    await into(hourBalancesTable).insertOnConflictUpdate(entry);
  }
}
