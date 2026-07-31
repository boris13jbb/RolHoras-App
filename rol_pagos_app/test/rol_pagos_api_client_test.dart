import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rol_pagos_app/services/rol_pagos_api_client.dart';

void main() {
  test('gmailStatus parsea respuesta JSON del backend', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/v1/integrations/gmail/status');
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response(
        '{"connected":true,"status":"active","email_address":"a@b.com"}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final client = RolPagosApiClient(
      baseUrl: 'http://localhost:8000',
      getAccessToken: () async => 'test-token',
      httpClient: mock,
    );

    final status = await client.gmailStatus(organizationId: 'org-1');
    expect(status['connected'], true);
    expect(status['status'], 'active');
    expect(status['email_address'], 'a@b.com');
  });
}
