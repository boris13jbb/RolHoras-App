// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hour_payments_dao.dart';

// ignore_for_file: type=lint
mixin _$HourPaymentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $HourPaymentsTableTable get hourPaymentsTable =>
      attachedDatabase.hourPaymentsTable;
  HourPaymentsDaoManager get managers => HourPaymentsDaoManager(this);
}

class HourPaymentsDaoManager {
  final _$HourPaymentsDaoMixin _db;
  HourPaymentsDaoManager(this._db);
  $$HourPaymentsTableTableTableManager get hourPaymentsTable =>
      $$HourPaymentsTableTableTableManager(
        _db.attachedDatabase,
        _db.hourPaymentsTable,
      );
}
