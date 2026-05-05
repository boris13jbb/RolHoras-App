import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/secure_storage_provider.dart';
import '../../../services/gmail_config_resolver.dart';
import 'gmail_providers.dart';
import 'gmail_sync_state.dart';

class GmailSyncController extends Notifier<GmailSyncState> {
  Timer? _autoTimer;

  @override
  GmailSyncState build() {
    _bootstrap();

    ref.listen(gmailAccountChangesProvider, (prev, next) {
      next.whenData((account) {
        state = state.copyWith(
          isConnected: account != null,
          connectedEmail: account?.email,
          connectedEmailToNull: account == null,
        );
        _refreshAutoTimer();
      });
    });

    return GmailSyncState.initial;
  }

  /// Tras guardar OAuth Web Client ID en almacén seguro: nuevo [GmailAuthService] e init.
  Future<void> reloadGmailConfiguration() async {
    ref.invalidate(gmailAuthServiceProvider);
    await _bootstrap();
  }

  Future<void> _bootstrap() async {
    final storage = ref.read(secureStorageServiceProvider);
    final enabled = await storage.getGmailAutoSyncEnabled();
    final sender = await storage.getGmailSenderFilter();
    state = state.copyWith(autoSyncEnabled: enabled, senderFilter: sender);

    final resolved = await resolveGmailServerClientId(storage);
    final auth = ref.read(gmailAuthServiceProvider);

    if (resolved == null || resolved.isEmpty) {
      state = state.copyWith(
        isConfigured: false,
        isConnected: false,
        connectedEmailToNull: true,
        lastResultMessage:
            'Falta el OAuth Web Client ID (cliente Web de Google Cloud). '
            'Pégalo en el campo de abajo y pulsa “Guardar Client ID”. '
            'Opcional: compilar con --dart-define=GMAIL_SERVER_CLIENT_ID=…',
      );
      _refreshAutoTimer();
      return;
    }

    try {
      await auth.initialize(serverClientId: resolved);
      state = state.copyWith(isConfigured: true, lastResultMessageToNull: true);
      final account = await auth.tryRestoreSession();
      state = state.copyWith(
        isConnected: account != null,
        connectedEmail: account?.email,
        connectedEmailToNull: account == null,
      );
    } catch (e) {
      state = state.copyWith(
        isConfigured: false,
        lastResultMessage:
            'No se pudo inicializar Google Sign-In. Verifica: (1) Client ID Web correcto, '
            '(2) en Google Cloud, tipo de aplicación Android con el mismo package y SHA-1 de firma. '
            'Detalle: $e',
      );
    }

    _refreshAutoTimer();
  }

  Future<void> connect() async {
    if (!state.isConfigured) {
      state = state.copyWith(
        lastResultMessage:
            'Configura primero el OAuth Web Client ID (campo de abajo) y pulsa “Guardar Client ID”.',
      );
      return;
    }
    final auth = ref.read(gmailAuthServiceProvider);
    try {
      final account = await auth.signIn();
      state = state.copyWith(
        isConnected: account != null,
        connectedEmail: account?.email,
        connectedEmailToNull: account == null,
        lastResultMessageToNull: true,
      );
      _refreshAutoTimer();
    } catch (e) {
      state = state.copyWith(
        lastResultMessage:
            'No se pudo conectar a Gmail. Revisa Client ID, SHA-1 y que Gmail API esté habilitada. Detalle: $e',
      );
    }
  }

  Future<void> disconnect() async {
    final auth = ref.read(gmailAuthServiceProvider);
    await auth.signOut();
    state = state.copyWith(
      isConnected: false,
      connectedEmailToNull: true,
      lastResultMessageToNull: true,
    );
    _refreshAutoTimer();
  }

  Future<void> setSenderFilter(String email) async {
    final storage = ref.read(secureStorageServiceProvider);
    final normalized = email.trim().toLowerCase();
    await storage.setGmailSenderFilter(normalized);
    state = state.copyWith(senderFilter: normalized);
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    final storage = ref.read(secureStorageServiceProvider);
    await storage.setGmailAutoSyncEnabled(enabled);
    state = state.copyWith(autoSyncEnabled: enabled);
    _refreshAutoTimer();
  }

  Future<void> syncNow() async {
    if (!state.isConnected) {
      state = state.copyWith(
        lastResultMessage: 'Conecta Gmail antes de sincronizar.',
      );
      return;
    }
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, lastResultMessageToNull: true);
    try {
      final sender = (state.senderFilter ?? '').trim();
      if (sender.isEmpty) {
        state = state.copyWith(
          lastResultMessage:
              'Configura primero el correo del remitente (quien envía el rol) y vuelve a intentar.',
        );
        return;
      }
      final storage = ref.read(secureStorageServiceProvider);
      final pdfPassword = (await storage.getPdfPassword())?.trim();

      final svc = ref.read(gmailSyncServiceProvider);
      final result = await svc.syncPayrollPdfs(
        senderEmail: sender,
        pdfPassword: pdfPassword,
      );
      state = state.copyWith(
        lastResultMessage:
            'Sincronización: ${result.imported} importados, '
            '${result.processed} procesados, '
            '${result.pendingPassword} pendientes contraseña, '
            '${result.duplicates} duplicados, '
            '${result.failed} fallidos.',
      );
    } catch (e) {
      state = state.copyWith(lastResultMessage: 'Error sincronizando: $e');
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  void _refreshAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = null;

    if (!state.autoSyncEnabled) return;
    if (!state.isConnected) return;

    _autoTimer = Timer.periodic(const Duration(hours: 6), (_) {
      syncNow();
    });

    ref.onDispose(() {
      _autoTimer?.cancel();
    });
  }
}
