import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _pdfPasswordKey = 'pdf_password';
  static const _gmailAutoSyncEnabledKey = 'gmail_auto_sync_enabled';
  static const _gmailSenderFilterKey = 'gmail_sender_filter';
  static const _gmailLastBgSyncAtKey = 'gmail_last_bg_sync_at';
  static const _gmailLastBgSyncResultKey = 'gmail_last_bg_sync_result';
  /// OAuth Web Client ID (tipo "Web application") para Google Sign-In / Gmail API.
  static const _gmailServerClientIdKey = 'gmail_server_client_id';

  final FlutterSecureStorage _storage;

  Future<void> savePdfPassword(String password) async {
    await _storage.write(key: _pdfPasswordKey, value: password);
  }

  Future<String?> getPdfPassword() async {
    return _storage.read(key: _pdfPasswordKey);
  }

  Future<void> deletePdfPassword() async {
    await _storage.delete(key: _pdfPasswordKey);
  }

  Future<bool> hasPdfPassword() async {
    final v = await getPdfPassword();
    return v != null && v.isNotEmpty;
  }

  Future<void> setGmailAutoSyncEnabled(bool enabled) async {
    await _storage.write(
      key: _gmailAutoSyncEnabledKey,
      value: enabled ? '1' : '0',
    );
  }

  Future<bool> getGmailAutoSyncEnabled() async {
    final v = await _storage.read(key: _gmailAutoSyncEnabledKey);
    return v == '1';
  }

  Future<void> setGmailSenderFilter(String email) async {
    await _storage.write(key: _gmailSenderFilterKey, value: email.trim());
  }

  Future<String?> getGmailSenderFilter() async {
    final v = await _storage.read(key: _gmailSenderFilterKey);
    if (v == null) return null;
    final trimmed = v.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> setGmailLastBackgroundSyncAt(DateTime at) async {
    await _storage.write(
      key: _gmailLastBgSyncAtKey,
      value: at.millisecondsSinceEpoch.toString(),
    );
  }

  Future<DateTime?> getGmailLastBackgroundSyncAt() async {
    final v = await _storage.read(key: _gmailLastBgSyncAtKey);
    final millis = int.tryParse((v ?? '').trim());
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setGmailLastBackgroundSyncResult(String result) async {
    await _storage.write(key: _gmailLastBgSyncResultKey, value: result.trim());
  }

  Future<String?> getGmailLastBackgroundSyncResult() async {
    final v = await _storage.read(key: _gmailLastBgSyncResultKey);
    final trimmed = (v ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> setGmailServerClientId(String clientId) async {
    await _storage.write(
      key: _gmailServerClientIdKey,
      value: clientId.trim(),
    );
  }

  Future<String?> getGmailServerClientId() async {
    final v = await _storage.read(key: _gmailServerClientIdKey);
    final trimmed = (v ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> deleteGmailServerClientId() async {
    await _storage.delete(key: _gmailServerClientIdKey);
  }
}
