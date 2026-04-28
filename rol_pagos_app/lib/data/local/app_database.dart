import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/hour_balances_dao.dart';
import 'daos/hour_payments_dao.dart';
import 'daos/payroll_documents_dao.dart';
import 'daos/user_settings_dao.dart';
import 'tables/hour_balances_table.dart';
import 'tables/hour_payments_table.dart';
import 'tables/payroll_documents_table.dart';
import 'tables/user_settings_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    HourPaymentsTable,
    HourBalancesTable,
    PayrollDocumentsTable,
    UserSettingsTable,
  ],
  daos: [
    HourPaymentsDao,
    HourBalancesDao,
    PayrollDocumentsDao,
    UserSettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {},
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'rol_pagos_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
