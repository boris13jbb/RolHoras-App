import 'package:drift/drift.dart';

class PayrollDocumentsTable extends Table {
  TextColumn get id => text()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();

  TextColumn get source => text()();
  TextColumn get senderEmail => text().nullable()();
  TextColumn get gmailMessageId => text().nullable()();
  TextColumn get gmailAttachmentId => text().nullable()();
  TextColumn get fileName => text()();
  TextColumn get localPath => text().nullable()();
  TextColumn get fileHash => text().nullable()();

  IntColumn get importedAtMillis => integer()();
  IntColumn get processedAtMillis => integer().nullable()();

  TextColumn get status => text()();
  TextColumn get extractedTextPreview => text().nullable()();

  RealColumn get detectedDebtHours => real().nullable()();
  RealColumn get detectedPaidHours => real().nullable()();
  RealColumn get detectedPendingHours => real().nullable()();

  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
