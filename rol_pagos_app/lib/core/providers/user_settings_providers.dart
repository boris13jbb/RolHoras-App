import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import 'app_database_provider.dart';

/// Configuración de usuario (singleton en Drift `id == 1`), vista reactiva.
///
/// Tras cada apertura de base de datos se garantiza la fila vía migración
/// [AppDatabase.migration.beforeOpen]; el stream sigue reflejando cambios futuros.
final userSettingsStreamProvider =
    StreamProvider<UserSettingsTableData?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.userSettingsDao.watchSettings();
});
