import 'secure_storage_service.dart';

/// Resuelve el **OAuth Web Client ID** (server client) requerido en Android por
/// `google_sign_in` para autorización con scopes de servidor (Gmail).
///
/// Prioridad:
/// 1. `--dart-define=GMAIL_SERVER_CLIENT_ID=...` (CI / builds automatizados)
/// 2. Valor guardado en `SecureStorageService` desde Configuración
Future<String?> resolveGmailServerClientId(SecureStorageService storage) async {
  const fromEnv = String.fromEnvironment(
    'GMAIL_SERVER_CLIENT_ID',
    defaultValue: '',
  );
  final trimmedEnv = fromEnv.trim();
  if (trimmedEnv.isNotEmpty) {
    return trimmedEnv;
  }
  final fromStorage = await storage.getGmailServerClientId();
  final trimmed = fromStorage?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

/// Validación laxa para evitar errores de pegado accidental.
bool looksLikeOAuthWebClientId(String value) {
  final v = value.trim();
  if (v.isEmpty) return false;
  // Formato habitual: 123456789-abc...xyz.apps.googleusercontent.com
  return v.endsWith('.apps.googleusercontent.com') && v.contains('-');
}
