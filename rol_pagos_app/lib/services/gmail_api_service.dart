import 'dart:convert';

import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:http/http.dart' as http;

import 'gmail_auth_service.dart';

class GmailApiService {
  GmailApiService({required GmailAuthService authService})
    : _authService = authService;

  final GmailAuthService _authService;

  Future<gmail.GmailApi> _api() async {
    final headers = await _authService.getAuthHeaders();
    final client = _GoogleAuthClient(headers);
    return gmail.GmailApi(client);
  }

  Future<List<gmail.Message>> listMessages({
    required String query,
    int maxResults = 20,
  }) async {
    final api = await _api();
    final resp = await api.users.messages.list(
      'me',
      q: query,
      maxResults: maxResults,
    );
    return resp.messages ?? const [];
  }

  Future<gmail.Message> getMessageFull(String messageId) async {
    final api = await _api();
    return api.users.messages.get('me', messageId, format: 'full');
  }

  Future<List<int>> downloadAttachmentBytes({
    required String messageId,
    required String attachmentId,
  }) async {
    final api = await _api();
    final body = await api.users.messages.attachments.get(
      'me',
      messageId,
      attachmentId,
    );

    final data = body.data;
    if (data == null || data.isEmpty) {
      return const [];
    }
    // Gmail usa base64url.
    return base64Url.decode(data);
  }
}

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers) : _inner = http.Client();

  final Map<String, String> _headers;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
