import 'package:drift/drift.dart';

class UserSettingsTable extends Table {
  IntColumn get id => integer()();

  BoolColumn get pdfPasswordSaved =>
      boolean().withDefault(const Constant(false))();
  TextColumn get defaultPercentagesJson => text()();
  TextColumn get gmailSenderFilter => text()();
  BoolColumn get autoSyncEnabled =>
      boolean().withDefault(const Constant(false))();

  IntColumn get createdAtMillis => integer()();
  IntColumn get updatedAtMillis => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
