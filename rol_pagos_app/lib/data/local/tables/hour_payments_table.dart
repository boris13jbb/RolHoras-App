import 'package:drift/drift.dart';

class HourPaymentsTable extends Table {
  TextColumn get id => text()();

  IntColumn get dateMillis => integer()();

  RealColumn get hours => real()();

  RealColumn get percentage => real()();

  RealColumn get equivalentHours => real()();

  TextColumn get observation => text().nullable()();

  IntColumn get payrollMonth => integer()();

  IntColumn get payrollYear => integer()();

  IntColumn get createdAtMillis => integer()();

  IntColumn get updatedAtMillis => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
