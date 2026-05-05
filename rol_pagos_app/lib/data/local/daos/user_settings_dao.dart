import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_settings_table.dart';

part 'user_settings_dao.g.dart';

/// DAO responsable de todas las operaciones de lectura y escritura
/// sobre la configuración de usuario ([UserSettingsTable]).
///
/// La configuración es un registro singleton identificado con `id = 1`.
@DriftAccessor(tables: [UserSettingsTable])
class UserSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.db);

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Emite la configuración del usuario en tiempo real.
  /// Devuelve `null` si el registro aún no ha sido creado.
  Stream<UserSettingsTableData?> watchSettings() {
    return (select(userSettingsTable)
          ..where((tbl) => tbl.id.equals(_kSettingsId)))
        .watchSingleOrNull();
  }

  /// Retorna una única vez la configuración actual, o `null` si no existe.
  Future<UserSettingsTableData?> getSettings() {
    return (select(userSettingsTable)
          ..where((tbl) => tbl.id.equals(_kSettingsId)))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Inserta la configuración por defecto **únicamente** si no existe
  /// un registro previo. Si ya existe, la operación no tiene efecto.
  Future<void> upsertDefaultsIfMissing() async {
    final alreadyExists = await _settingsExist();
    if (alreadyExists) return;

    await _insertDefaultSettings();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Verifica si el registro de configuración ya fue creado.
  Future<bool> _settingsExist() async {
    final record = await getSettings();
    return record != null;
  }

  /// Inserta el registro de configuración inicial con valores derivados
  /// del contrato laboral vigente (ver notas de negocio abajo).
  Future<void> _insertDefaultSettings() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await into(userSettingsTable).insert(
      UserSettingsTableCompanion(
        id: const Value(_kSettingsId),
        pdfPasswordSaved: const Value(false),
        defaultPercentagesJson: Value(jsonEncode(_kDefaultPercentages)),
        gmailSenderFilter: const Value(_kDefaultGmailSender),
        autoSyncEnabled: const Value(false),
        createdAtMillis: Value(now),
        updatedAtMillis: Value(now),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Constantes
  // ---------------------------------------------------------------------------

  /// ID fijo del registro singleton de configuración.
  static const int _kSettingsId = 1;

  /// Remitente por defecto para el filtro de sincronización por Gmail.
  static const String _kDefaultGmailSender = 'XXXXX@vicunha.com.ec';

  /// Porcentajes base derivados del contrato laboral (fotos de referencia).
  ///
  /// | Valor  | Concepto                                        |
  /// |--------|-------------------------------------------------|
  /// | 100.0  | Hora normal (100 %)                             |
  /// | 50.0   | Media hora / recargo base                       |
  /// | 30.0   | Recargo adicional base                          |
  /// | 120.0  | Recargo adicional 20 %                          |
  /// | 125.0  | Recargo adicional 25 %                          |
  /// | 130.0  | Equivalencia 1 → 1.30                           |
  /// | 200.0  | Descanso normal: 2 días compensados             |
  /// | 240.0  | 2 días compensados + 20 % (2 × 1.20)            |
  /// | 250.0  | 2 días compensados + 25 % — p. ej. domingo 3er turno |
  static const List<double> _kDefaultPercentages = [
    100.0,
    50.0,
    30.0,
    120.0,
    125.0,
    130.0,
    200.0,
    240.0,
    250.0,
  ];
}
