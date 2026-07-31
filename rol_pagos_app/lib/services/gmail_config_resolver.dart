import '../data/local/app_database.dart';
import 'gmail_auth_service.dart';
import 'secure_storage_service.dart';

/// Limpia un Client ID pegado con basura típica (URL, espacios, comillas).
String? normalizeOAuthWebClientId(String? raw) {
  if (raw == null) return null;
  var v = raw.trim();
  if (v.isEmpty) return null;

  // Pegados accidentales: URL completa o con prefijo https://
  v = v.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
  v = v.split(RegExp(r'[/\s?#]')).first.trim();
  v = v.replaceAll('"', '').replaceAll("'", '');

  // Si pegaron "client_id=...."
  final eq = RegExp(r'client_id=([^&\s]+)', caseSensitive: false).firstMatch(v);
  if (eq != null) {
    v = eq.group(1)!.trim();
  }

  return v.isEmpty ? null : v;
}

/// Prefijo del proyecto Firebase `rol-pagos-saas-b7b04` (debe coincidir con
/// `google-services.json`). Un Client ID de otro proyecto provoca `[28444]`.
const String expectedOAuthProjectNumberPrefix = '398451651219-';

bool isAlignedWithAndroidOAuthProject(String clientId) {
  final v = normalizeOAuthWebClientId(clientId);
  if (v == null) return false;
  return v.startsWith(expectedOAuthProjectNumberPrefix);
}

/// Resuelve el **OAuth Web Client ID** (server client) requerido en Android por
/// `google_sign_in` para autorización con scopes de servidor (Gmail).
///
/// Prioridad:
/// 1. `--dart-define=GMAIL_SERVER_CLIENT_ID=...` (CI / builds automatizados)
/// 2. Valor en `SecureStorageService` si es del proyecto correcto
/// 3. [GmailAuthService.recommendedWebClientId] (autocorrección)
Future<String?> resolveGmailServerClientId(SecureStorageService storage) async {
  const fromEnv = String.fromEnvironment(
    'GMAIL_SERVER_CLIENT_ID',
    defaultValue: '',
  );
  final trimmedEnv = normalizeOAuthWebClientId(fromEnv);
  if (trimmedEnv != null && trimmedEnv.isNotEmpty) {
    return trimmedEnv;
  }

  final fromStorage = normalizeOAuthWebClientId(
    await storage.getGmailServerClientId(),
  );
  if (fromStorage != null &&
      fromStorage.isNotEmpty &&
      isAlignedWithAndroidOAuthProject(fromStorage)) {
    return fromStorage;
  }

  final recommended = GmailAuthService.recommendedWebClientId;
  if (fromStorage != recommended) {
    await storage.setGmailServerClientId(recommended);
  }
  return recommended;
}

/// Validación laxa para evitar errores de pegado accidental.
bool looksLikeOAuthWebClientId(String value) {
  final v = normalizeOAuthWebClientId(value);
  if (v == null || v.isEmpty) return false;
  // Formato habitual: 123456789-abc...xyz.apps.googleusercontent.com
  return v.endsWith('.apps.googleusercontent.com') && v.contains('-');
}

/// Valor de remitente aceptable para promoverlo desde la fila Drift al almacén seguro.
///
/// Excluye placeholders de seed (p. ej. `XXXXX@vicunha.com.ec`).
bool isUsableGmailSenderStoredValue(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.isEmpty || !s.contains('@')) return false;
  if (s.contains('xxxxx')) return false;
  return true;
}

/// Remitente efectivo para Gmail: almacén seguro, o —si está vacío— `user_settings` en Drift
/// (persistido de vuelta en almacén seguro para WorkManager y próximos arranques).
Future<String?> resolveGmailSenderFilterForSync(
  SecureStorageService storage,
  AppDatabase db,
) async {
  final fromSecure = await storage.getGmailSenderFilter();
  final trimmedSecure = fromSecure?.trim() ?? '';
  if (trimmedSecure.isNotEmpty) {
    return trimmedSecure.toLowerCase();
  }
  final row = await db.userSettingsDao.getSettings();
  final fromDb = row?.gmailSenderFilter ?? '';
  if (!isUsableGmailSenderStoredValue(fromDb)) return null;
  final normalized = fromDb.trim().toLowerCase();
  await storage.setGmailSenderFilter(normalized);
  return normalized;
}
