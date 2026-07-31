import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../services/rol_pagos_api_client.dart';

const _apiBaseUrlKey = 'saas_api_base_url';
const _apiAccessTokenKey = 'saas_api_access_token';
const _organizationIdKey = 'saas_organization_id';

/// Configuración SaaS persistida (URL API, JWT, organización activa).
final saasConfigProvider = FutureProvider<SaasConfig>((ref) async {
  const storage = FlutterSecureStorage();
  final baseUrl =
      await storage.read(key: _apiBaseUrlKey) ?? 'https://rolpagos-api.onrender.com';
  final token = await storage.read(key: _apiAccessTokenKey);
  final orgId = await storage.read(key: _organizationIdKey);
  return SaasConfig(baseUrl: baseUrl, accessToken: token, organizationId: orgId);
});

final rolPagosApiClientProvider = Provider<RolPagosApiClient>((ref) {
  final configAsync = ref.watch(saasConfigProvider);
  final config = configAsync.asData?.value;
  return RolPagosApiClient(
    baseUrl: config?.baseUrl ?? 'https://rolpagos-api.onrender.com',
    getAccessToken: () async {
      const storage = FlutterSecureStorage();
      return storage.read(key: _apiAccessTokenKey);
    },
  );
});

class SaasConfig {
  const SaasConfig({
    required this.baseUrl,
    this.accessToken,
    this.organizationId,
  });

  final String baseUrl;
  final String? accessToken;
  final String? organizationId;

  bool get isReady =>
      accessToken != null &&
      accessToken!.isNotEmpty &&
      organizationId != null &&
      organizationId!.isNotEmpty;
}

class SaasConfigRepository {
  SaasConfigRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> save({
    required String baseUrl,
    required String accessToken,
    required String organizationId,
  }) async {
    await _storage.write(key: _apiBaseUrlKey, value: baseUrl);
    await _storage.write(key: _apiAccessTokenKey, value: accessToken);
    await _storage.write(key: _organizationIdKey, value: organizationId);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _apiAccessTokenKey);
    await _storage.delete(key: _organizationIdKey);
  }
}
