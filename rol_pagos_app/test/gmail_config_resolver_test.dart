import 'package:flutter_test/flutter_test.dart';
import 'package:rol_pagos_app/services/gmail_config_resolver.dart';

void main() {
  group('normalizeOAuthWebClientId', () {
    test('limpia https y espacios', () {
      expect(
        normalizeOAuthWebClientId(
          '  https://123-abc.apps.googleusercontent.com  ',
        ),
        '123-abc.apps.googleusercontent.com',
      );
    });

    test('extrae client_id de query', () {
      expect(
        normalizeOAuthWebClientId(
          'client_id=999-xyz.apps.googleusercontent.com&foo=1',
        ),
        '999-xyz.apps.googleusercontent.com',
      );
    });

    test('looksLikeOAuthWebClientId rechaza basura', () {
      expect(looksLikeOAuthWebClientId('https://'), isFalse);
      expect(
        looksLikeOAuthWebClientId(
          '1026-abc.apps.googleusercontent.com',
        ),
        isTrue,
      );
    });

    test('isAlignedWithAndroidOAuthProject solo acepta prefijo Firebase', () {
      expect(
        isAlignedWithAndroidOAuthProject(
          '398451651219-6lblq3morscifre6ka35jmtk01db4k0l.apps.googleusercontent.com',
        ),
        isTrue,
      );
      expect(
        isAlignedWithAndroidOAuthProject(
          '338527142470-93djr7icjq75hp0jcvluf4q4taff07ai.apps.googleusercontent.com',
        ),
        isFalse,
      );
    });
  });
}
