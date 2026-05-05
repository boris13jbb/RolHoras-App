import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/payroll_documents_table.dart';

part 'payroll_documents_dao.g.dart';

@DriftAccessor(tables: [PayrollDocumentsTable])
class PayrollDocumentsDao extends DatabaseAccessor<AppDatabase>
    with _$PayrollDocumentsDaoMixin {
  PayrollDocumentsDao(super.db);

  Stream<List<PayrollDocumentsTableData>> watchAll() {
    return (select(
      payrollDocumentsTable,
    )..orderBy([(t) => OrderingTerm.desc(t.importedAtMillis)])).watch();
  }

  Future<PayrollDocumentsTableData?> findByHash(String hash) {
    return (select(
      payrollDocumentsTable,
    )..where((t) => t.fileHash.equals(hash))).getSingleOrNull();
  }

  Future<PayrollDocumentsTableData?> findById(String id) {
    return (select(
      payrollDocumentsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<PayrollDocumentsTableData?> findByGmailAttachment({
    required String messageId,
    required String attachmentId,
  }) {
    return (select(payrollDocumentsTable)..where(
          (t) =>
              t.gmailMessageId.equals(messageId) &
              t.gmailAttachmentId.equals(attachmentId),
        ))
        .getSingleOrNull();
  }

  Future<void> upsert(PayrollDocumentsTableCompanion entry) async {
    await into(payrollDocumentsTable).insertOnConflictUpdate(entry);
  }

  Future<int> deleteById(String id) {
    return (delete(payrollDocumentsTable)..where((t) => t.id.equals(id))).go();
  }
}
