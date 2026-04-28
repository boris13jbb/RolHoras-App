// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hour_balances_dao.dart';

// ignore_for_file: type=lint
mixin _$HourBalancesDaoMixin on DatabaseAccessor<AppDatabase> {
  $HourBalancesTableTable get hourBalancesTable =>
      attachedDatabase.hourBalancesTable;
  HourBalancesDaoManager get managers => HourBalancesDaoManager(this);
}

class HourBalancesDaoManager {
  final _$HourBalancesDaoMixin _db;
  HourBalancesDaoManager(this._db);
  $$HourBalancesTableTableTableManager get hourBalancesTable =>
      $$HourBalancesTableTableTableManager(
        _db.attachedDatabase,
        _db.hourBalancesTable,
      );
}
