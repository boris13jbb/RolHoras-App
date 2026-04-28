import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../services/secure_storage_service.dart';
import '../services/gmail_config_resolver.dart';
import '../services/gmail_auth_service.dart';
import '../services/gmail_api_service.dart';
import '../services/gmail_sync_service.dart';
import '../data/local/app_database.dart';
import '../features/payroll/data/payroll_repository.dart';

const String kTaskGmailSync = 'gmail_sync_task';

/// Entrada del isolate de background.
///
/// Debe ser top-level y marcada con entry-point para evitar tree-shaking.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    // Guardrails: si no está habilitado por el usuario, no hacemos nada.
    final storage = SecureStorageService();
    final enabled = await storage.getGmailAutoSyncEnabled();
    if (!enabled) return true;

    if (task != kTaskGmailSync) return true;

    try {
      final sender = await storage.getGmailSenderFilter();

      final resolved = await resolveGmailServerClientId(storage);
      if (resolved == null || resolved.isEmpty) {
        await storage.setGmailLastBackgroundSyncResult(
          'BG omitido: falta OAuth Web Client ID en Configuración.',
        );
        await storage.setGmailLastBackgroundSyncAt(DateTime.now());
        return true;
      }

      final auth = GmailAuthService();
      await auth.initialize(serverClientId: resolved);
      await auth.tryRestoreSession();

      // Evitar prompts UI en background.
      await auth.getAuthHeaders(promptIfNecessary: false);

      final db = AppDatabase();
      final payrollRepo = PayrollRepository(db: db);
      final gmailApi = GmailApiService(authService: auth);
      final sync = GmailSyncService(
        gmailApi: gmailApi,
        payrollRepository: payrollRepo,
      );

      final result = await sync.syncPayrollPdfs(senderEmail: sender);
      await storage.setGmailLastBackgroundSyncResult(
        'BG: ${result.imported} importados, ${result.duplicates} duplicados, ${result.failed} fallidos.',
      );
      await storage.setGmailLastBackgroundSyncAt(DateTime.now());

      await db.close();
      return true;
    } catch (e) {
      await storage.setGmailLastBackgroundSyncResult('BG error: $e');
      await storage.setGmailLastBackgroundSyncAt(DateTime.now());
      return true; // No reintentar agresivo; se reporta en UI.
    }
  });
}

class BackgroundTasks {
  const BackgroundTasks._();

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  static Future<void> registerGmailSync() async {
    // Cada 6 horas, como la configuración original.
    await Workmanager().registerPeriodicTask(
      kTaskGmailSync,
      kTaskGmailSync,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> cancelGmailSync() async {
    await Workmanager().cancelByUniqueName(kTaskGmailSync);
  }
}

