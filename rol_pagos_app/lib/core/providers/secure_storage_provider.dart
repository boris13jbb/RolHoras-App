import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/secure_storage_service.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final pdfPasswordExistsProvider = FutureProvider<bool>((ref) async {
  return ref.watch(secureStorageServiceProvider).hasPdfPassword();
});
