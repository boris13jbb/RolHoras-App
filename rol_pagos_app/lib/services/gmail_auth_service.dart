import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'gmail_config_resolver.dart';

/// Servicio de autenticación Gmail basado en OAuth (Google Sign-In).
///
/// En Android (`google_sign_in` >= 7), para scopes de servidor como Gmail suele
/// hacer falta **OAuth Web Client ID** pasado como `serverClientId` en
/// [initialize].
///
/// Nota: Para tareas 100% en segundo plano sin UI, la renovación de tokens puede
/// requerir estrategias adicionales según políticas de Google.
class GmailAuthService {
  GmailAuthService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static const gmailScopes = [
    'email',
    'profile',
    'https://www.googleapis.com/auth/gmail.readonly',
  ];

  /// Package de la app Android en `build.gradle.kts` (requerido en Google Cloud).
  static const String androidPackageName = 'com.rolhoras.rol_pagos_app';

  /// SHA-1 del keystore debug local (para cliente OAuth Android).
  static const String debugSha1Fingerprint =
      'FA:BA:45:3F:E3:71:8A:26:10:4B:3B:A7:7F:96:7E:10:4D:6C:B2:51';

  /// Client ID Web (type 3) del proyecto Firebase `rol-pagos-saas-b7b04`.
  /// Debe usarse como `serverClientId` en Android para scopes de Gmail.
  static const String recommendedWebClientId =
      '398451651219-6lblq3morscifre6ka35jmtk01db4k0l.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn;

  GoogleSignInAccount? _currentUser;

  /// Suscripción principal a eventos; se cancela en cada [initialize] para no
  /// duplicar listeners al invalidar providers.
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  Stream<GoogleSignInAccount?> get onCurrentUserChanged => _googleSignIn
      .authenticationEvents
      .map((event) {
        return switch (event) {
          GoogleSignInAuthenticationEventSignIn() => event.user,
          GoogleSignInAuthenticationEventSignOut() => null,
        };
      })
      // El plugin hace `addError` al stream antes de relanzar; sin esto aparece
      // «Unhandled asynchronous error» aun cuando el Future se captura.
      .handleError((Object _) {});

  void _wireAuthenticationEventsListener() {
    _authSubscription = _googleSignIn.authenticationEvents.listen(
      (event) {
        _currentUser = switch (event) {
          GoogleSignInAuthenticationEventSignIn() => event.user,
          GoogleSignInAuthenticationEventSignOut() => null,
        };
      },
      onError: (Object error, StackTrace stackTrace) {
        // Mismo caso: addError + rethrow en attemptLightweightAuthentication / authenticate.
        if (kDebugMode) {
          debugPrint('GmailAuthService authenticationEvents.onError: $error');
        }
      },
    );
  }

  GoogleSignInAccount? get currentUser => _currentUser;

  /// [serverClientId]: Cliente OAuth tipo **Web application** (Console Google Cloud).
  Future<void> initialize({String? serverClientId}) async {
    final trimmed = normalizeOAuthWebClientId(serverClientId) ?? '';
    await _authSubscription?.cancel();
    _authSubscription = null;

    await _googleSignIn.initialize(
      serverClientId: trimmed.isEmpty ? null : trimmed,
    );
    _wireAuthenticationEventsListener();
  }

  /// Restaura sesión sin UI. Errores de Google (p. ej. consola mal configurada)
  /// se tratan como “sin sesión” para no dejar excepciones sin capturar.
  Future<GoogleSignInAccount?> tryRestoreSession() async {
    try {
      final lightweightFuture = _googleSignIn
          .attemptLightweightAuthentication();
      // Importante: el Future devuelve la cuenta restaurada; no basta con leer
      // _currentUser (el listener puede ir un frame detrás o no dispararse aún).
      if (lightweightFuture != null) {
        final account = await lightweightFuture;
        if (account != null) {
          _currentUser = account;
        }
        return account;
      }
      // Si la plataforma usa solo el stream (future == null), dar margen a que
      // llegue el evento de inicio de sesión.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return _currentUser;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('GmailAuthService.tryRestoreSession: $e');
        debugPrint('$st');
      }
      return null;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    if (!_googleSignIn.supportsAuthenticate()) {
      throw StateError(
        'Este dispositivo/plataforma no soporta authenticate() para Google Sign-In.',
      );
    }
    try {
      await _googleSignIn.authenticate(scopeHint: gmailScopes);
    } on GoogleSignInException catch (e) {
      throw Exception(_describeGoogleSignInFailure(e));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('GmailAuthService.signIn: $e\n$st');
      }
      rethrow;
    }
    return _currentUser;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<Map<String, String>> getAuthHeaders({
    bool promptIfNecessary = true,
  }) async {
    final user = _currentUser ?? (await tryRestoreSession());
    if (user == null) {
      throw StateError('No hay sesión de Gmail. Conecta tu cuenta primero.');
    }

    final headers = await user.authorizationClient.authorizationHeaders(
      gmailScopes,
      promptIfNecessary: promptIfNecessary,
    );
    if (headers == null || headers.isEmpty) {
      throw StateError(
        'No se pudo obtener headers de autorización para Gmail.',
      );
    }
    return headers;
  }
}

String _describeGoogleSignInFailure(GoogleSignInException e) {
  final raw = e.toString();
  final lower = raw.toLowerCase();
  if (lower.contains('28444') ||
      lower.contains('developer console is not set up') ||
      lower.contains('account reauth failed') ||
      lower.contains('[16]')) {
    return 'Google Sign-In en Android no está alineado con el proyecto OAuth. '
        'Proyecto Firebase: rol-pagos-saas-b7b04.\n'
        '1) Google Cloud → Credenciales → cliente OAuth tipo Android\n'
        '2) Package: ${GmailAuthService.androidPackageName}\n'
        '3) SHA-1 debug: ${GmailAuthService.debugSha1Fingerprint}\n'
        '4) Crea/usa un Client ID Web del MISMO proyecto y pégalo en Ajustes\n'
        '5) Vuelve a descargar google-services.json (debe incluir oauth_client)\n'
        'Mientras tanto usa el panel web: https://rol-pagos-admin.vercel.app/gmail';
  }
  if (lower.contains('canceled') || lower.contains('cancelled')) {
    return 'Inicio de sesión cancelado. Si no cancelaste tú, revisa el cliente '
        'Android OAuth (package + SHA-1) o usa https://rol-pagos-admin.vercel.app/gmail';
  }
  return raw;
}
