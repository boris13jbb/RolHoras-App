import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_settings_table.dart';

part 'user_settings_dao.g.dart';

@DriftAccessor(tables: [UserSettingsTable])
class UserSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.db);

  Stream<UserSettingsTableData?> watchSettings() {
    return (select(
      userSettingsTable,
    )..where((tbl) => tbl.id.equals(1))).watchSingleOrNull();
  }

  Future<void> upsertDefaultsIfMissing() async {
    final existing = await (select(
      userSettingsTable,
    )..where((tbl) => tbl.id.equals(1))).getSingleOrNull();

    if (existing != null) {
      return;
    }

    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    await into(userSettingsTable).insert(
      UserSettingsTableCompanion(
        id: const Value(1),
        pdfPasswordSaved: const Value(false),
        // Basado en el contrato (fotos): recargos 20%/25%, equivalencia 1→1.30,
        // y compensación por descanso (2 días) + recargo aplicado.
        defaultPercentagesJson: Value(
          jsonEncode([
            100.0,
            50.0,
            30.0,
            120.0, // Recargo adicional 20%
            125.0, // Recargo adicional 25%
            130.0, // Equivalencia 1 → 1.30
            200.0, // Descanso normal: 2 días compensados
            240.0, // 2 días compensados + 20% (2 * 1.20)
            250.0, // 2 días compensados + 25% (2 * 1.25) (p.ej. domingo 3er turno)
          ]),
        ),
        gmailSenderFilter: const Value('galo.tapia@vicunha.com.ec'),
        autoSyncEnabled: const Value(false),
        createdAtMillis: Value(nowMillis),
        updatedAtMillis: Value(nowMillis),
      ),
    );
  }
}
