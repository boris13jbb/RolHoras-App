import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cliente HTTP hacia la API SaaS (Gmail OAuth offline en backend).
class RolPagosApiClient {
  RolPagosApiClient({
    required this.baseUrl,
    required this.getAccessToken,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() getAccessToken;
  final http.Client _http;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$normalized$path').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers() async {
    final token = await getAccessToken();
    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> gmailAuthorize({required String organizationId}) async {
    final res = await _http.get(
      _uri('/api/v1/integrations/gmail/authorize', {'organization_id': organizationId}),
      headers: await _headers(),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> gmailStatus({required String organizationId}) async {
    final res = await _http.get(
      _uri('/api/v1/integrations/gmail/status', {'organization_id': organizationId}),
      headers: await _headers(),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> gmailSync({
    required String organizationId,
    bool full = false,
  }) async {
    final res = await _http.post(
      _uri('/api/v1/integrations/gmail/sync', {
        'organization_id': organizationId,
        if (full) 'full': 'true',
      }),
      headers: await _headers(),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateGmailFilters({
    required String organizationId,
    required String senderFilter,
    String? subjectPattern,
  }) async {
    final body = <String, dynamic>{'sender_filter': senderFilter};
    if (subjectPattern != null) {
      body['subject_pattern'] = subjectPattern;
    }
    final res = await _http.put(
      _uri('/api/v1/settings/gmail-filters', {'organization_id': organizationId}),
      headers: {
        ...await _headers(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGmailFilters({
    required String organizationId,
  }) async {
    final res = await _http.get(
      _uri('/api/v1/settings/gmail-filters', {'organization_id': organizationId}),
      headers: await _headers(),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> gmailDisconnect({required String organizationId}) async {
    final res = await _http.delete(
      _uri('/api/v1/integrations/gmail', {'organization_id': organizationId}),
      headers: await _headers(),
    );
    _ensureOk(res);
  }

  Future<List<dynamic>> listDocuments({required String organizationId}) async {
    final res = await _http.get(
      _uri('/api/v1/documents', {'organization_id': organizationId}),
      headers: await _headers(),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<List<dynamic>> listBalances({required String organizationId}) async {
    final res = await _http.get(
      _uri('/api/v1/hours/balances', {'organization_id': organizationId}),
      headers: await _headers(),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw RolPagosApiException(res.statusCode, res.body);
  }
}

class RolPagosApiException implements Exception {
  RolPagosApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'RolPagosApiException($statusCode): $body';
}
