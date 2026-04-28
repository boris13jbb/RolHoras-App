// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_documents_dao.dart';

// ignore_for_file: type=lint
mixin _$PayrollDocumentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PayrollDocumentsTableTable get payrollDocumentsTable =>
      attachedDatabase.payrollDocumentsTable;
  PayrollDocumentsDaoManager get managers => PayrollDocumentsDaoManager(this);
}

class PayrollDocumentsDaoManager {
  final _$PayrollDocumentsDaoMixin _db;
  PayrollDocumentsDaoManager(this._db);
  $$PayrollDocumentsTableTableTableManager get payrollDocumentsTable =>
      $$PayrollDocumentsTableTableTableManager(
        _db.attachedDatabase,
        _db.payrollDocumentsTable,
      );
}
