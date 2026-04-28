import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../services/gmail_api_service.dart';
import '../../../services/gmail_auth_service.dart';
import '../../../services/gmail_sync_service.dart';
import '../../payroll/application/payroll_providers.dart';
import 'gmail_sync_controller.dart';
import 'gmail_sync_state.dart';

/// Invalidar con [Ref.invalidate] tras cambiar OAuth Web Client ID guardado.
final gmailAuthServiceProvider = Provider<GmailAuthService>((ref) {
  return GmailAuthService();
});

final gmailApiServiceProvider = Provider<GmailApiService>((ref) {
  final auth = ref.watch(gmailAuthServiceProvider);
  return GmailApiService(authService: auth);
});

final gmailSyncServiceProvider = Provider<GmailSyncService>((ref) {
  final gmailApi = ref.watch(gmailApiServiceProvider);
  final payrollRepo = ref.watch(payrollRepositoryProvider);
  return GmailSyncService(gmailApi: gmailApi, payrollRepository: payrollRepo);
});

final gmailSyncControllerProvider =
    NotifierProvider<GmailSyncController, GmailSyncState>(
      GmailSyncController.new,
    );

final gmailAccountChangesProvider = StreamProvider<GoogleSignInAccount?>((
  ref,
) {
  final auth = ref.watch(gmailAuthServiceProvider);
  return auth.onCurrentUserChanged;
});
