import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_database_provider.dart';
import '../data/payroll_repository.dart';
import '../domain/payroll_document.dart';

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PayrollRepository(db: db);
});

final payrollDocumentsProvider = StreamProvider<List<PayrollDocument>>((ref) {
  return ref.watch(payrollRepositoryProvider).watchPayrolls();
});
