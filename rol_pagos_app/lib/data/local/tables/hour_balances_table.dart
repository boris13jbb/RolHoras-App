import 'package:drift/drift.dart';

class HourBalancesTable extends Table {
  IntColumn get year => integer()();
  IntColumn get month => integer()();

  RealColumn get totalDebtHours => real()();
  RealColumn get totalPaidEquivalentHours => real()();
  RealColumn get pendingHours => real()();
  RealColumn get overtimeHours => real()();
  TextColumn get status => text()();
  IntColumn get calculatedAtMillis => integer()();

  @override
  Set<Column<Object>> get primaryKey => {year, month};
}
