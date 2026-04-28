// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HourPaymentsTableTable extends HourPaymentsTable
    with TableInfo<$HourPaymentsTableTable, HourPaymentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HourPaymentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMillisMeta = const VerificationMeta(
    'dateMillis',
  );
  @override
  late final GeneratedColumn<int> dateMillis = GeneratedColumn<int>(
    'date_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hoursMeta = const VerificationMeta('hours');
  @override
  late final GeneratedColumn<double> hours = GeneratedColumn<double>(
    'hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentageMeta = const VerificationMeta(
    'percentage',
  );
  @override
  late final GeneratedColumn<double> percentage = GeneratedColumn<double>(
    'percentage',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equivalentHoursMeta = const VerificationMeta(
    'equivalentHours',
  );
  @override
  late final GeneratedColumn<double> equivalentHours = GeneratedColumn<double>(
    'equivalent_hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observationMeta = const VerificationMeta(
    'observation',
  );
  @override
  late final GeneratedColumn<String> observation = GeneratedColumn<String>(
    'observation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payrollMonthMeta = const VerificationMeta(
    'payrollMonth',
  );
  @override
  late final GeneratedColumn<int> payrollMonth = GeneratedColumn<int>(
    'payroll_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payrollYearMeta = const VerificationMeta(
    'payrollYear',
  );
  @override
  late final GeneratedColumn<int> payrollYear = GeneratedColumn<int>(
    'payroll_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMillisMeta = const VerificationMeta(
    'createdAtMillis',
  );
  @override
  late final GeneratedColumn<int> createdAtMillis = GeneratedColumn<int>(
    'created_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMillisMeta = const VerificationMeta(
    'updatedAtMillis',
  );
  @override
  late final GeneratedColumn<int> updatedAtMillis = GeneratedColumn<int>(
    'updated_at_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dateMillis,
    hours,
    percentage,
    equivalentHours,
    observation,
    payrollMonth,
    payrollYear,
    createdAtMillis,
    updatedAtMillis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hour_payments_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<HourPaymentsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date_millis')) {
      context.handle(
        _dateMillisMeta,
        dateMillis.isAcceptableOrUnknown(data['date_millis']!, _dateMillisMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMillisMeta);
    }
    if (data.containsKey('hours')) {
      context.handle(
        _hoursMeta,
        hours.isAcceptableOrUnknown(data['hours']!, _hoursMeta),
      );
    } else if (isInserting) {
      context.missing(_hoursMeta);
    }
    if (data.containsKey('percentage')) {
      context.handle(
        _percentageMeta,
        percentage.isAcceptableOrUnknown(data['percentage']!, _percentageMeta),
      );
    } else if (isInserting) {
      context.missing(_percentageMeta);
    }
    if (data.containsKey('equivalent_hours')) {
      context.handle(
        _equivalentHoursMeta,
        equivalentHours.isAcceptableOrUnknown(
          data['equivalent_hours']!,
          _equivalentHoursMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_equivalentHoursMeta);
    }
    if (data.containsKey('observation')) {
      context.handle(
        _observationMeta,
        observation.isAcceptableOrUnknown(
          data['observation']!,
          _observationMeta,
        ),
      );
    }
    if (data.containsKey('payroll_month')) {
      context.handle(
        _payrollMonthMeta,
        payrollMonth.isAcceptableOrUnknown(
          data['payroll_month']!,
          _payrollMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payrollMonthMeta);
    }
    if (data.containsKey('payroll_year')) {
      context.handle(
        _payrollYearMeta,
        payrollYear.isAcceptableOrUnknown(
          data['payroll_year']!,
          _payrollYearMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payrollYearMeta);
    }
    if (data.containsKey('created_at_millis')) {
      context.handle(
        _createdAtMillisMeta,
        createdAtMillis.isAcceptableOrUnknown(
          data['created_at_millis']!,
          _createdAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMillisMeta);
    }
    if (data.containsKey('updated_at_millis')) {
      context.handle(
        _updatedAtMillisMeta,
        updatedAtMillis.isAcceptableOrUnknown(
          data['updated_at_millis']!,
          _updatedAtMillisMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HourPaymentsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HourPaymentsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dateMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_millis'],
      )!,
      hours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hours'],
      )!,
      percentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percentage'],
      )!,
      equivalentHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}equivalent_hours'],
      )!,
      observation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observation'],
      ),
      payrollMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payroll_month'],
      )!,
      payrollYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payroll_year'],
      )!,
      createdAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_millis'],
      )!,
      updatedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_millis'],
      ),
    );
  }

  @override
  $HourPaymentsTableTable createAlias(String alias) {
    return $HourPaymentsTableTable(attachedDatabase, alias);
  }
}

class HourPaymentsTableData extends DataClass
    implements Insertable<HourPaymentsTableData> {
  final String id;
  final int dateMillis;
  final double hours;
  final double percentage;
  final double equivalentHours;
  final String? observation;
  final int payrollMonth;
  final int payrollYear;
  final int createdAtMillis;
  final int? updatedAtMillis;
  const HourPaymentsTableData({
    required this.id,
    required this.dateMillis,
    required this.hours,
    required this.percentage,
    required this.equivalentHours,
    this.observation,
    required this.payrollMonth,
    required this.payrollYear,
    required this.createdAtMillis,
    this.updatedAtMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date_millis'] = Variable<int>(dateMillis);
    map['hours'] = Variable<double>(hours);
    map['percentage'] = Variable<double>(percentage);
    map['equivalent_hours'] = Variable<double>(equivalentHours);
    if (!nullToAbsent || observation != null) {
      map['observation'] = Variable<String>(observation);
    }
    map['payroll_month'] = Variable<int>(payrollMonth);
    map['payroll_year'] = Variable<int>(payrollYear);
    map['created_at_millis'] = Variable<int>(createdAtMillis);
    if (!nullToAbsent || updatedAtMillis != null) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis);
    }
    return map;
  }

  HourPaymentsTableCompanion toCompanion(bool nullToAbsent) {
    return HourPaymentsTableCompanion(
      id: Value(id),
      dateMillis: Value(dateMillis),
      hours: Value(hours),
      percentage: Value(percentage),
      equivalentHours: Value(equivalentHours),
      observation: observation == null && nullToAbsent
          ? const Value.absent()
          : Value(observation),
      payrollMonth: Value(payrollMonth),
      payrollYear: Value(payrollYear),
      createdAtMillis: Value(createdAtMillis),
      updatedAtMillis: updatedAtMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAtMillis),
    );
  }

  factory HourPaymentsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HourPaymentsTableData(
      id: serializer.fromJson<String>(json['id']),
      dateMillis: serializer.fromJson<int>(json['dateMillis']),
      hours: serializer.fromJson<double>(json['hours']),
      percentage: serializer.fromJson<double>(json['percentage']),
      equivalentHours: serializer.fromJson<double>(json['equivalentHours']),
      observation: serializer.fromJson<String?>(json['observation']),
      payrollMonth: serializer.fromJson<int>(json['payrollMonth']),
      payrollYear: serializer.fromJson<int>(json['payrollYear']),
      createdAtMillis: serializer.fromJson<int>(json['createdAtMillis']),
      updatedAtMillis: serializer.fromJson<int?>(json['updatedAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dateMillis': serializer.toJson<int>(dateMillis),
      'hours': serializer.toJson<double>(hours),
      'percentage': serializer.toJson<double>(percentage),
      'equivalentHours': serializer.toJson<double>(equivalentHours),
      'observation': serializer.toJson<String?>(observation),
      'payrollMonth': serializer.toJson<int>(payrollMonth),
      'payrollYear': serializer.toJson<int>(payrollYear),
      'createdAtMillis': serializer.toJson<int>(createdAtMillis),
      'updatedAtMillis': serializer.toJson<int?>(updatedAtMillis),
    };
  }

  HourPaymentsTableData copyWith({
    String? id,
    int? dateMillis,
    double? hours,
    double? percentage,
    double? equivalentHours,
    Value<String?> observation = const Value.absent(),
    int? payrollMonth,
    int? payrollYear,
    int? createdAtMillis,
    Value<int?> updatedAtMillis = const Value.absent(),
  }) => HourPaymentsTableData(
    id: id ?? this.id,
    dateMillis: dateMillis ?? this.dateMillis,
    hours: hours ?? this.hours,
    percentage: percentage ?? this.percentage,
    equivalentHours: equivalentHours ?? this.equivalentHours,
    observation: observation.present ? observation.value : this.observation,
    payrollMonth: payrollMonth ?? this.payrollMonth,
    payrollYear: payrollYear ?? this.payrollYear,
    createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    updatedAtMillis: updatedAtMillis.present
        ? updatedAtMillis.value
        : this.updatedAtMillis,
  );
  HourPaymentsTableData copyWithCompanion(HourPaymentsTableCompanion data) {
    return HourPaymentsTableData(
      id: data.id.present ? data.id.value : this.id,
      dateMillis: data.dateMillis.present
          ? data.dateMillis.value
          : this.dateMillis,
      hours: data.hours.present ? data.hours.value : this.hours,
      percentage: data.percentage.present
          ? data.percentage.value
          : this.percentage,
      equivalentHours: data.equivalentHours.present
          ? data.equivalentHours.value
          : this.equivalentHours,
      observation: data.observation.present
          ? data.observation.value
          : this.observation,
      payrollMonth: data.payrollMonth.present
          ? data.payrollMonth.value
          : this.payrollMonth,
      payrollYear: data.payrollYear.present
          ? data.payrollYear.value
          : this.payrollYear,
      createdAtMillis: data.createdAtMillis.present
          ? data.createdAtMillis.value
          : this.createdAtMillis,
      updatedAtMillis: data.updatedAtMillis.present
          ? data.updatedAtMillis.value
          : this.updatedAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HourPaymentsTableData(')
          ..write('id: $id, ')
          ..write('dateMillis: $dateMillis, ')
          ..write('hours: $hours, ')
          ..write('percentage: $percentage, ')
          ..write('equivalentHours: $equivalentHours, ')
          ..write('observation: $observation, ')
          ..write('payrollMonth: $payrollMonth, ')
          ..write('payrollYear: $payrollYear, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dateMillis,
    hours,
    percentage,
    equivalentHours,
    observation,
    payrollMonth,
    payrollYear,
    createdAtMillis,
    updatedAtMillis,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HourPaymentsTableData &&
          other.id == this.id &&
          other.dateMillis == this.dateMillis &&
          other.hours == this.hours &&
          other.percentage == this.percentage &&
          other.equivalentHours == this.equivalentHours &&
          other.observation == this.observation &&
          other.payrollMonth == this.payrollMonth &&
          other.payrollYear == this.payrollYear &&
          other.createdAtMillis == this.createdAtMillis &&
          other.updatedAtMillis == this.updatedAtMillis);
}

class HourPaymentsTableCompanion
    extends UpdateCompanion<HourPaymentsTableData> {
  final Value<String> id;
  final Value<int> dateMillis;
  final Value<double> hours;
  final Value<double> percentage;
  final Value<double> equivalentHours;
  final Value<String?> observation;
  final Value<int> payrollMonth;
  final Value<int> payrollYear;
  final Value<int> createdAtMillis;
  final Value<int?> updatedAtMillis;
  final Value<int> rowid;
  const HourPaymentsTableCompanion({
    this.id = const Value.absent(),
    this.dateMillis = const Value.absent(),
    this.hours = const Value.absent(),
    this.percentage = const Value.absent(),
    this.equivalentHours = const Value.absent(),
    this.observation = const Value.absent(),
    this.payrollMonth = const Value.absent(),
    this.payrollYear = const Value.absent(),
    this.createdAtMillis = const Value.absent(),
    this.updatedAtMillis = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HourPaymentsTableCompanion.insert({
    required String id,
    required int dateMillis,
    required double hours,
    required double percentage,
    required double equivalentHours,
    this.observation = const Value.absent(),
    required int payrollMonth,
    required int payrollYear,
    required int createdAtMillis,
    this.updatedAtMillis = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dateMillis = Value(dateMillis),
       hours = Value(hours),
       percentage = Value(percentage),
       equivalentHours = Value(equivalentHours),
       payrollMonth = Value(payrollMonth),
       payrollYear = Value(payrollYear),
       createdAtMillis = Value(createdAtMillis);
  static Insertable<HourPaymentsTableData> custom({
    Expression<String>? id,
    Expression<int>? dateMillis,
    Expression<double>? hours,
    Expression<double>? percentage,
    Expression<double>? equivalentHours,
    Expression<String>? observation,
    Expression<int>? payrollMonth,
    Expression<int>? payrollYear,
    Expression<int>? createdAtMillis,
    Expression<int>? updatedAtMillis,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dateMillis != null) 'date_millis': dateMillis,
      if (hours != null) 'hours': hours,
      if (percentage != null) 'percentage': percentage,
      if (equivalentHours != null) 'equivalent_hours': equivalentHours,
      if (observation != null) 'observation': observation,
      if (payrollMonth != null) 'payroll_month': payrollMonth,
      if (payrollYear != null) 'payroll_year': payrollYear,
      if (createdAtMillis != null) 'created_at_millis': createdAtMillis,
      if (updatedAtMillis != null) 'updated_at_millis': updatedAtMillis,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HourPaymentsTableCompanion copyWith({
    Value<String>? id,
    Value<int>? dateMillis,
    Value<double>? hours,
    Value<double>? percentage,
    Value<double>? equivalentHours,
    Value<String?>? observation,
    Value<int>? payrollMonth,
    Value<int>? payrollYear,
    Value<int>? createdAtMillis,
    Value<int?>? updatedAtMillis,
    Value<int>? rowid,
  }) {
    return HourPaymentsTableCompanion(
      id: id ?? this.id,
      dateMillis: dateMillis ?? this.dateMillis,
      hours: hours ?? this.hours,
      percentage: percentage ?? this.percentage,
      equivalentHours: equivalentHours ?? this.equivalentHours,
      observation: observation ?? this.observation,
      payrollMonth: payrollMonth ?? this.payrollMonth,
      payrollYear: payrollYear ?? this.payrollYear,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dateMillis.present) {
      map['date_millis'] = Variable<int>(dateMillis.value);
    }
    if (hours.present) {
      map['hours'] = Variable<double>(hours.value);
    }
    if (percentage.present) {
      map['percentage'] = Variable<double>(percentage.value);
    }
    if (equivalentHours.present) {
      map['equivalent_hours'] = Variable<double>(equivalentHours.value);
    }
    if (observation.present) {
      map['observation'] = Variable<String>(observation.value);
    }
    if (payrollMonth.present) {
      map['payroll_month'] = Variable<int>(payrollMonth.value);
    }
    if (payrollYear.present) {
      map['payroll_year'] = Variable<int>(payrollYear.value);
    }
    if (createdAtMillis.present) {
      map['created_at_millis'] = Variable<int>(createdAtMillis.value);
    }
    if (updatedAtMillis.present) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HourPaymentsTableCompanion(')
          ..write('id: $id, ')
          ..write('dateMillis: $dateMillis, ')
          ..write('hours: $hours, ')
          ..write('percentage: $percentage, ')
          ..write('equivalentHours: $equivalentHours, ')
          ..write('observation: $observation, ')
          ..write('payrollMonth: $payrollMonth, ')
          ..write('payrollYear: $payrollYear, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HourBalancesTableTable extends HourBalancesTable
    with TableInfo<$HourBalancesTableTable, HourBalancesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HourBalancesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalDebtHoursMeta = const VerificationMeta(
    'totalDebtHours',
  );
  @override
  late final GeneratedColumn<double> totalDebtHours = GeneratedColumn<double>(
    'total_debt_hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPaidEquivalentHoursMeta =
      const VerificationMeta('totalPaidEquivalentHours');
  @override
  late final GeneratedColumn<double> totalPaidEquivalentHours =
      GeneratedColumn<double>(
        'total_paid_equivalent_hours',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _pendingHoursMeta = const VerificationMeta(
    'pendingHours',
  );
  @override
  late final GeneratedColumn<double> pendingHours = GeneratedColumn<double>(
    'pending_hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overtimeHoursMeta = const VerificationMeta(
    'overtimeHours',
  );
  @override
  late final GeneratedColumn<double> overtimeHours = GeneratedColumn<double>(
    'overtime_hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calculatedAtMillisMeta =
      const VerificationMeta('calculatedAtMillis');
  @override
  late final GeneratedColumn<int> calculatedAtMillis = GeneratedColumn<int>(
    'calculated_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    year,
    month,
    totalDebtHours,
    totalPaidEquivalentHours,
    pendingHours,
    overtimeHours,
    status,
    calculatedAtMillis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hour_balances_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<HourBalancesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('total_debt_hours')) {
      context.handle(
        _totalDebtHoursMeta,
        totalDebtHours.isAcceptableOrUnknown(
          data['total_debt_hours']!,
          _totalDebtHoursMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalDebtHoursMeta);
    }
    if (data.containsKey('total_paid_equivalent_hours')) {
      context.handle(
        _totalPaidEquivalentHoursMeta,
        totalPaidEquivalentHours.isAcceptableOrUnknown(
          data['total_paid_equivalent_hours']!,
          _totalPaidEquivalentHoursMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalPaidEquivalentHoursMeta);
    }
    if (data.containsKey('pending_hours')) {
      context.handle(
        _pendingHoursMeta,
        pendingHours.isAcceptableOrUnknown(
          data['pending_hours']!,
          _pendingHoursMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pendingHoursMeta);
    }
    if (data.containsKey('overtime_hours')) {
      context.handle(
        _overtimeHoursMeta,
        overtimeHours.isAcceptableOrUnknown(
          data['overtime_hours']!,
          _overtimeHoursMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_overtimeHoursMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('calculated_at_millis')) {
      context.handle(
        _calculatedAtMillisMeta,
        calculatedAtMillis.isAcceptableOrUnknown(
          data['calculated_at_millis']!,
          _calculatedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calculatedAtMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {year, month};
  @override
  HourBalancesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HourBalancesTableData(
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      totalDebtHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_debt_hours'],
      )!,
      totalPaidEquivalentHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_paid_equivalent_hours'],
      )!,
      pendingHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pending_hours'],
      )!,
      overtimeHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}overtime_hours'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      calculatedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calculated_at_millis'],
      )!,
    );
  }

  @override
  $HourBalancesTableTable createAlias(String alias) {
    return $HourBalancesTableTable(attachedDatabase, alias);
  }
}

class HourBalancesTableData extends DataClass
    implements Insertable<HourBalancesTableData> {
  final int year;
  final int month;
  final double totalDebtHours;
  final double totalPaidEquivalentHours;
  final double pendingHours;
  final double overtimeHours;
  final String status;
  final int calculatedAtMillis;
  const HourBalancesTableData({
    required this.year,
    required this.month,
    required this.totalDebtHours,
    required this.totalPaidEquivalentHours,
    required this.pendingHours,
    required this.overtimeHours,
    required this.status,
    required this.calculatedAtMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['total_debt_hours'] = Variable<double>(totalDebtHours);
    map['total_paid_equivalent_hours'] = Variable<double>(
      totalPaidEquivalentHours,
    );
    map['pending_hours'] = Variable<double>(pendingHours);
    map['overtime_hours'] = Variable<double>(overtimeHours);
    map['status'] = Variable<String>(status);
    map['calculated_at_millis'] = Variable<int>(calculatedAtMillis);
    return map;
  }

  HourBalancesTableCompanion toCompanion(bool nullToAbsent) {
    return HourBalancesTableCompanion(
      year: Value(year),
      month: Value(month),
      totalDebtHours: Value(totalDebtHours),
      totalPaidEquivalentHours: Value(totalPaidEquivalentHours),
      pendingHours: Value(pendingHours),
      overtimeHours: Value(overtimeHours),
      status: Value(status),
      calculatedAtMillis: Value(calculatedAtMillis),
    );
  }

  factory HourBalancesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HourBalancesTableData(
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      totalDebtHours: serializer.fromJson<double>(json['totalDebtHours']),
      totalPaidEquivalentHours: serializer.fromJson<double>(
        json['totalPaidEquivalentHours'],
      ),
      pendingHours: serializer.fromJson<double>(json['pendingHours']),
      overtimeHours: serializer.fromJson<double>(json['overtimeHours']),
      status: serializer.fromJson<String>(json['status']),
      calculatedAtMillis: serializer.fromJson<int>(json['calculatedAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'totalDebtHours': serializer.toJson<double>(totalDebtHours),
      'totalPaidEquivalentHours': serializer.toJson<double>(
        totalPaidEquivalentHours,
      ),
      'pendingHours': serializer.toJson<double>(pendingHours),
      'overtimeHours': serializer.toJson<double>(overtimeHours),
      'status': serializer.toJson<String>(status),
      'calculatedAtMillis': serializer.toJson<int>(calculatedAtMillis),
    };
  }

  HourBalancesTableData copyWith({
    int? year,
    int? month,
    double? totalDebtHours,
    double? totalPaidEquivalentHours,
    double? pendingHours,
    double? overtimeHours,
    String? status,
    int? calculatedAtMillis,
  }) => HourBalancesTableData(
    year: year ?? this.year,
    month: month ?? this.month,
    totalDebtHours: totalDebtHours ?? this.totalDebtHours,
    totalPaidEquivalentHours:
        totalPaidEquivalentHours ?? this.totalPaidEquivalentHours,
    pendingHours: pendingHours ?? this.pendingHours,
    overtimeHours: overtimeHours ?? this.overtimeHours,
    status: status ?? this.status,
    calculatedAtMillis: calculatedAtMillis ?? this.calculatedAtMillis,
  );
  HourBalancesTableData copyWithCompanion(HourBalancesTableCompanion data) {
    return HourBalancesTableData(
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      totalDebtHours: data.totalDebtHours.present
          ? data.totalDebtHours.value
          : this.totalDebtHours,
      totalPaidEquivalentHours: data.totalPaidEquivalentHours.present
          ? data.totalPaidEquivalentHours.value
          : this.totalPaidEquivalentHours,
      pendingHours: data.pendingHours.present
          ? data.pendingHours.value
          : this.pendingHours,
      overtimeHours: data.overtimeHours.present
          ? data.overtimeHours.value
          : this.overtimeHours,
      status: data.status.present ? data.status.value : this.status,
      calculatedAtMillis: data.calculatedAtMillis.present
          ? data.calculatedAtMillis.value
          : this.calculatedAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HourBalancesTableData(')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('totalDebtHours: $totalDebtHours, ')
          ..write('totalPaidEquivalentHours: $totalPaidEquivalentHours, ')
          ..write('pendingHours: $pendingHours, ')
          ..write('overtimeHours: $overtimeHours, ')
          ..write('status: $status, ')
          ..write('calculatedAtMillis: $calculatedAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    year,
    month,
    totalDebtHours,
    totalPaidEquivalentHours,
    pendingHours,
    overtimeHours,
    status,
    calculatedAtMillis,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HourBalancesTableData &&
          other.year == this.year &&
          other.month == this.month &&
          other.totalDebtHours == this.totalDebtHours &&
          other.totalPaidEquivalentHours == this.totalPaidEquivalentHours &&
          other.pendingHours == this.pendingHours &&
          other.overtimeHours == this.overtimeHours &&
          other.status == this.status &&
          other.calculatedAtMillis == this.calculatedAtMillis);
}

class HourBalancesTableCompanion
    extends UpdateCompanion<HourBalancesTableData> {
  final Value<int> year;
  final Value<int> month;
  final Value<double> totalDebtHours;
  final Value<double> totalPaidEquivalentHours;
  final Value<double> pendingHours;
  final Value<double> overtimeHours;
  final Value<String> status;
  final Value<int> calculatedAtMillis;
  final Value<int> rowid;
  const HourBalancesTableCompanion({
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.totalDebtHours = const Value.absent(),
    this.totalPaidEquivalentHours = const Value.absent(),
    this.pendingHours = const Value.absent(),
    this.overtimeHours = const Value.absent(),
    this.status = const Value.absent(),
    this.calculatedAtMillis = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HourBalancesTableCompanion.insert({
    required int year,
    required int month,
    required double totalDebtHours,
    required double totalPaidEquivalentHours,
    required double pendingHours,
    required double overtimeHours,
    required String status,
    required int calculatedAtMillis,
    this.rowid = const Value.absent(),
  }) : year = Value(year),
       month = Value(month),
       totalDebtHours = Value(totalDebtHours),
       totalPaidEquivalentHours = Value(totalPaidEquivalentHours),
       pendingHours = Value(pendingHours),
       overtimeHours = Value(overtimeHours),
       status = Value(status),
       calculatedAtMillis = Value(calculatedAtMillis);
  static Insertable<HourBalancesTableData> custom({
    Expression<int>? year,
    Expression<int>? month,
    Expression<double>? totalDebtHours,
    Expression<double>? totalPaidEquivalentHours,
    Expression<double>? pendingHours,
    Expression<double>? overtimeHours,
    Expression<String>? status,
    Expression<int>? calculatedAtMillis,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (totalDebtHours != null) 'total_debt_hours': totalDebtHours,
      if (totalPaidEquivalentHours != null)
        'total_paid_equivalent_hours': totalPaidEquivalentHours,
      if (pendingHours != null) 'pending_hours': pendingHours,
      if (overtimeHours != null) 'overtime_hours': overtimeHours,
      if (status != null) 'status': status,
      if (calculatedAtMillis != null)
        'calculated_at_millis': calculatedAtMillis,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HourBalancesTableCompanion copyWith({
    Value<int>? year,
    Value<int>? month,
    Value<double>? totalDebtHours,
    Value<double>? totalPaidEquivalentHours,
    Value<double>? pendingHours,
    Value<double>? overtimeHours,
    Value<String>? status,
    Value<int>? calculatedAtMillis,
    Value<int>? rowid,
  }) {
    return HourBalancesTableCompanion(
      year: year ?? this.year,
      month: month ?? this.month,
      totalDebtHours: totalDebtHours ?? this.totalDebtHours,
      totalPaidEquivalentHours:
          totalPaidEquivalentHours ?? this.totalPaidEquivalentHours,
      pendingHours: pendingHours ?? this.pendingHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      status: status ?? this.status,
      calculatedAtMillis: calculatedAtMillis ?? this.calculatedAtMillis,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (totalDebtHours.present) {
      map['total_debt_hours'] = Variable<double>(totalDebtHours.value);
    }
    if (totalPaidEquivalentHours.present) {
      map['total_paid_equivalent_hours'] = Variable<double>(
        totalPaidEquivalentHours.value,
      );
    }
    if (pendingHours.present) {
      map['pending_hours'] = Variable<double>(pendingHours.value);
    }
    if (overtimeHours.present) {
      map['overtime_hours'] = Variable<double>(overtimeHours.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (calculatedAtMillis.present) {
      map['calculated_at_millis'] = Variable<int>(calculatedAtMillis.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HourBalancesTableCompanion(')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('totalDebtHours: $totalDebtHours, ')
          ..write('totalPaidEquivalentHours: $totalPaidEquivalentHours, ')
          ..write('pendingHours: $pendingHours, ')
          ..write('overtimeHours: $overtimeHours, ')
          ..write('status: $status, ')
          ..write('calculatedAtMillis: $calculatedAtMillis, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PayrollDocumentsTableTable extends PayrollDocumentsTable
    with TableInfo<$PayrollDocumentsTableTable, PayrollDocumentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PayrollDocumentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderEmailMeta = const VerificationMeta(
    'senderEmail',
  );
  @override
  late final GeneratedColumn<String> senderEmail = GeneratedColumn<String>(
    'sender_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gmailMessageIdMeta = const VerificationMeta(
    'gmailMessageId',
  );
  @override
  late final GeneratedColumn<String> gmailMessageId = GeneratedColumn<String>(
    'gmail_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gmailAttachmentIdMeta = const VerificationMeta(
    'gmailAttachmentId',
  );
  @override
  late final GeneratedColumn<String> gmailAttachmentId =
      GeneratedColumn<String>(
        'gmail_attachment_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importedAtMillisMeta = const VerificationMeta(
    'importedAtMillis',
  );
  @override
  late final GeneratedColumn<int> importedAtMillis = GeneratedColumn<int>(
    'imported_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processedAtMillisMeta = const VerificationMeta(
    'processedAtMillis',
  );
  @override
  late final GeneratedColumn<int> processedAtMillis = GeneratedColumn<int>(
    'processed_at_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extractedTextPreviewMeta =
      const VerificationMeta('extractedTextPreview');
  @override
  late final GeneratedColumn<String> extractedTextPreview =
      GeneratedColumn<String>(
        'extracted_text_preview',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _detectedDebtHoursMeta = const VerificationMeta(
    'detectedDebtHours',
  );
  @override
  late final GeneratedColumn<double> detectedDebtHours =
      GeneratedColumn<double>(
        'detected_debt_hours',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _detectedPaidHoursMeta = const VerificationMeta(
    'detectedPaidHours',
  );
  @override
  late final GeneratedColumn<double> detectedPaidHours =
      GeneratedColumn<double>(
        'detected_paid_hours',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _detectedPendingHoursMeta =
      const VerificationMeta('detectedPendingHours');
  @override
  late final GeneratedColumn<double> detectedPendingHours =
      GeneratedColumn<double>(
        'detected_pending_hours',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    year,
    month,
    source,
    senderEmail,
    gmailMessageId,
    gmailAttachmentId,
    fileName,
    localPath,
    fileHash,
    importedAtMillis,
    processedAtMillis,
    status,
    extractedTextPreview,
    detectedDebtHours,
    detectedPaidHours,
    detectedPendingHours,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payroll_documents_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PayrollDocumentsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('sender_email')) {
      context.handle(
        _senderEmailMeta,
        senderEmail.isAcceptableOrUnknown(
          data['sender_email']!,
          _senderEmailMeta,
        ),
      );
    }
    if (data.containsKey('gmail_message_id')) {
      context.handle(
        _gmailMessageIdMeta,
        gmailMessageId.isAcceptableOrUnknown(
          data['gmail_message_id']!,
          _gmailMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('gmail_attachment_id')) {
      context.handle(
        _gmailAttachmentIdMeta,
        gmailAttachmentId.isAcceptableOrUnknown(
          data['gmail_attachment_id']!,
          _gmailAttachmentIdMeta,
        ),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    }
    if (data.containsKey('imported_at_millis')) {
      context.handle(
        _importedAtMillisMeta,
        importedAtMillis.isAcceptableOrUnknown(
          data['imported_at_millis']!,
          _importedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_importedAtMillisMeta);
    }
    if (data.containsKey('processed_at_millis')) {
      context.handle(
        _processedAtMillisMeta,
        processedAtMillis.isAcceptableOrUnknown(
          data['processed_at_millis']!,
          _processedAtMillisMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('extracted_text_preview')) {
      context.handle(
        _extractedTextPreviewMeta,
        extractedTextPreview.isAcceptableOrUnknown(
          data['extracted_text_preview']!,
          _extractedTextPreviewMeta,
        ),
      );
    }
    if (data.containsKey('detected_debt_hours')) {
      context.handle(
        _detectedDebtHoursMeta,
        detectedDebtHours.isAcceptableOrUnknown(
          data['detected_debt_hours']!,
          _detectedDebtHoursMeta,
        ),
      );
    }
    if (data.containsKey('detected_paid_hours')) {
      context.handle(
        _detectedPaidHoursMeta,
        detectedPaidHours.isAcceptableOrUnknown(
          data['detected_paid_hours']!,
          _detectedPaidHoursMeta,
        ),
      );
    }
    if (data.containsKey('detected_pending_hours')) {
      context.handle(
        _detectedPendingHoursMeta,
        detectedPendingHours.isAcceptableOrUnknown(
          data['detected_pending_hours']!,
          _detectedPendingHoursMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PayrollDocumentsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PayrollDocumentsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      senderEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_email'],
      ),
      gmailMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gmail_message_id'],
      ),
      gmailAttachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gmail_attachment_id'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      ),
      importedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imported_at_millis'],
      )!,
      processedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}processed_at_millis'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      extractedTextPreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_text_preview'],
      ),
      detectedDebtHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}detected_debt_hours'],
      ),
      detectedPaidHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}detected_paid_hours'],
      ),
      detectedPendingHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}detected_pending_hours'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $PayrollDocumentsTableTable createAlias(String alias) {
    return $PayrollDocumentsTableTable(attachedDatabase, alias);
  }
}

class PayrollDocumentsTableData extends DataClass
    implements Insertable<PayrollDocumentsTableData> {
  final String id;
  final int year;
  final int month;
  final String source;
  final String? senderEmail;
  final String? gmailMessageId;
  final String? gmailAttachmentId;
  final String fileName;
  final String? localPath;
  final String? fileHash;
  final int importedAtMillis;
  final int? processedAtMillis;
  final String status;
  final String? extractedTextPreview;
  final double? detectedDebtHours;
  final double? detectedPaidHours;
  final double? detectedPendingHours;
  final String? notes;
  const PayrollDocumentsTableData({
    required this.id,
    required this.year,
    required this.month,
    required this.source,
    this.senderEmail,
    this.gmailMessageId,
    this.gmailAttachmentId,
    required this.fileName,
    this.localPath,
    this.fileHash,
    required this.importedAtMillis,
    this.processedAtMillis,
    required this.status,
    this.extractedTextPreview,
    this.detectedDebtHours,
    this.detectedPaidHours,
    this.detectedPendingHours,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || senderEmail != null) {
      map['sender_email'] = Variable<String>(senderEmail);
    }
    if (!nullToAbsent || gmailMessageId != null) {
      map['gmail_message_id'] = Variable<String>(gmailMessageId);
    }
    if (!nullToAbsent || gmailAttachmentId != null) {
      map['gmail_attachment_id'] = Variable<String>(gmailAttachmentId);
    }
    map['file_name'] = Variable<String>(fileName);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || fileHash != null) {
      map['file_hash'] = Variable<String>(fileHash);
    }
    map['imported_at_millis'] = Variable<int>(importedAtMillis);
    if (!nullToAbsent || processedAtMillis != null) {
      map['processed_at_millis'] = Variable<int>(processedAtMillis);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || extractedTextPreview != null) {
      map['extracted_text_preview'] = Variable<String>(extractedTextPreview);
    }
    if (!nullToAbsent || detectedDebtHours != null) {
      map['detected_debt_hours'] = Variable<double>(detectedDebtHours);
    }
    if (!nullToAbsent || detectedPaidHours != null) {
      map['detected_paid_hours'] = Variable<double>(detectedPaidHours);
    }
    if (!nullToAbsent || detectedPendingHours != null) {
      map['detected_pending_hours'] = Variable<double>(detectedPendingHours);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  PayrollDocumentsTableCompanion toCompanion(bool nullToAbsent) {
    return PayrollDocumentsTableCompanion(
      id: Value(id),
      year: Value(year),
      month: Value(month),
      source: Value(source),
      senderEmail: senderEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(senderEmail),
      gmailMessageId: gmailMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(gmailMessageId),
      gmailAttachmentId: gmailAttachmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(gmailAttachmentId),
      fileName: Value(fileName),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      fileHash: fileHash == null && nullToAbsent
          ? const Value.absent()
          : Value(fileHash),
      importedAtMillis: Value(importedAtMillis),
      processedAtMillis: processedAtMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(processedAtMillis),
      status: Value(status),
      extractedTextPreview: extractedTextPreview == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedTextPreview),
      detectedDebtHours: detectedDebtHours == null && nullToAbsent
          ? const Value.absent()
          : Value(detectedDebtHours),
      detectedPaidHours: detectedPaidHours == null && nullToAbsent
          ? const Value.absent()
          : Value(detectedPaidHours),
      detectedPendingHours: detectedPendingHours == null && nullToAbsent
          ? const Value.absent()
          : Value(detectedPendingHours),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory PayrollDocumentsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PayrollDocumentsTableData(
      id: serializer.fromJson<String>(json['id']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      source: serializer.fromJson<String>(json['source']),
      senderEmail: serializer.fromJson<String?>(json['senderEmail']),
      gmailMessageId: serializer.fromJson<String?>(json['gmailMessageId']),
      gmailAttachmentId: serializer.fromJson<String?>(
        json['gmailAttachmentId'],
      ),
      fileName: serializer.fromJson<String>(json['fileName']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      fileHash: serializer.fromJson<String?>(json['fileHash']),
      importedAtMillis: serializer.fromJson<int>(json['importedAtMillis']),
      processedAtMillis: serializer.fromJson<int?>(json['processedAtMillis']),
      status: serializer.fromJson<String>(json['status']),
      extractedTextPreview: serializer.fromJson<String?>(
        json['extractedTextPreview'],
      ),
      detectedDebtHours: serializer.fromJson<double?>(
        json['detectedDebtHours'],
      ),
      detectedPaidHours: serializer.fromJson<double?>(
        json['detectedPaidHours'],
      ),
      detectedPendingHours: serializer.fromJson<double?>(
        json['detectedPendingHours'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'source': serializer.toJson<String>(source),
      'senderEmail': serializer.toJson<String?>(senderEmail),
      'gmailMessageId': serializer.toJson<String?>(gmailMessageId),
      'gmailAttachmentId': serializer.toJson<String?>(gmailAttachmentId),
      'fileName': serializer.toJson<String>(fileName),
      'localPath': serializer.toJson<String?>(localPath),
      'fileHash': serializer.toJson<String?>(fileHash),
      'importedAtMillis': serializer.toJson<int>(importedAtMillis),
      'processedAtMillis': serializer.toJson<int?>(processedAtMillis),
      'status': serializer.toJson<String>(status),
      'extractedTextPreview': serializer.toJson<String?>(extractedTextPreview),
      'detectedDebtHours': serializer.toJson<double?>(detectedDebtHours),
      'detectedPaidHours': serializer.toJson<double?>(detectedPaidHours),
      'detectedPendingHours': serializer.toJson<double?>(detectedPendingHours),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  PayrollDocumentsTableData copyWith({
    String? id,
    int? year,
    int? month,
    String? source,
    Value<String?> senderEmail = const Value.absent(),
    Value<String?> gmailMessageId = const Value.absent(),
    Value<String?> gmailAttachmentId = const Value.absent(),
    String? fileName,
    Value<String?> localPath = const Value.absent(),
    Value<String?> fileHash = const Value.absent(),
    int? importedAtMillis,
    Value<int?> processedAtMillis = const Value.absent(),
    String? status,
    Value<String?> extractedTextPreview = const Value.absent(),
    Value<double?> detectedDebtHours = const Value.absent(),
    Value<double?> detectedPaidHours = const Value.absent(),
    Value<double?> detectedPendingHours = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => PayrollDocumentsTableData(
    id: id ?? this.id,
    year: year ?? this.year,
    month: month ?? this.month,
    source: source ?? this.source,
    senderEmail: senderEmail.present ? senderEmail.value : this.senderEmail,
    gmailMessageId: gmailMessageId.present
        ? gmailMessageId.value
        : this.gmailMessageId,
    gmailAttachmentId: gmailAttachmentId.present
        ? gmailAttachmentId.value
        : this.gmailAttachmentId,
    fileName: fileName ?? this.fileName,
    localPath: localPath.present ? localPath.value : this.localPath,
    fileHash: fileHash.present ? fileHash.value : this.fileHash,
    importedAtMillis: importedAtMillis ?? this.importedAtMillis,
    processedAtMillis: processedAtMillis.present
        ? processedAtMillis.value
        : this.processedAtMillis,
    status: status ?? this.status,
    extractedTextPreview: extractedTextPreview.present
        ? extractedTextPreview.value
        : this.extractedTextPreview,
    detectedDebtHours: detectedDebtHours.present
        ? detectedDebtHours.value
        : this.detectedDebtHours,
    detectedPaidHours: detectedPaidHours.present
        ? detectedPaidHours.value
        : this.detectedPaidHours,
    detectedPendingHours: detectedPendingHours.present
        ? detectedPendingHours.value
        : this.detectedPendingHours,
    notes: notes.present ? notes.value : this.notes,
  );
  PayrollDocumentsTableData copyWithCompanion(
    PayrollDocumentsTableCompanion data,
  ) {
    return PayrollDocumentsTableData(
      id: data.id.present ? data.id.value : this.id,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      source: data.source.present ? data.source.value : this.source,
      senderEmail: data.senderEmail.present
          ? data.senderEmail.value
          : this.senderEmail,
      gmailMessageId: data.gmailMessageId.present
          ? data.gmailMessageId.value
          : this.gmailMessageId,
      gmailAttachmentId: data.gmailAttachmentId.present
          ? data.gmailAttachmentId.value
          : this.gmailAttachmentId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      importedAtMillis: data.importedAtMillis.present
          ? data.importedAtMillis.value
          : this.importedAtMillis,
      processedAtMillis: data.processedAtMillis.present
          ? data.processedAtMillis.value
          : this.processedAtMillis,
      status: data.status.present ? data.status.value : this.status,
      extractedTextPreview: data.extractedTextPreview.present
          ? data.extractedTextPreview.value
          : this.extractedTextPreview,
      detectedDebtHours: data.detectedDebtHours.present
          ? data.detectedDebtHours.value
          : this.detectedDebtHours,
      detectedPaidHours: data.detectedPaidHours.present
          ? data.detectedPaidHours.value
          : this.detectedPaidHours,
      detectedPendingHours: data.detectedPendingHours.present
          ? data.detectedPendingHours.value
          : this.detectedPendingHours,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PayrollDocumentsTableData(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('source: $source, ')
          ..write('senderEmail: $senderEmail, ')
          ..write('gmailMessageId: $gmailMessageId, ')
          ..write('gmailAttachmentId: $gmailAttachmentId, ')
          ..write('fileName: $fileName, ')
          ..write('localPath: $localPath, ')
          ..write('fileHash: $fileHash, ')
          ..write('importedAtMillis: $importedAtMillis, ')
          ..write('processedAtMillis: $processedAtMillis, ')
          ..write('status: $status, ')
          ..write('extractedTextPreview: $extractedTextPreview, ')
          ..write('detectedDebtHours: $detectedDebtHours, ')
          ..write('detectedPaidHours: $detectedPaidHours, ')
          ..write('detectedPendingHours: $detectedPendingHours, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    year,
    month,
    source,
    senderEmail,
    gmailMessageId,
    gmailAttachmentId,
    fileName,
    localPath,
    fileHash,
    importedAtMillis,
    processedAtMillis,
    status,
    extractedTextPreview,
    detectedDebtHours,
    detectedPaidHours,
    detectedPendingHours,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PayrollDocumentsTableData &&
          other.id == this.id &&
          other.year == this.year &&
          other.month == this.month &&
          other.source == this.source &&
          other.senderEmail == this.senderEmail &&
          other.gmailMessageId == this.gmailMessageId &&
          other.gmailAttachmentId == this.gmailAttachmentId &&
          other.fileName == this.fileName &&
          other.localPath == this.localPath &&
          other.fileHash == this.fileHash &&
          other.importedAtMillis == this.importedAtMillis &&
          other.processedAtMillis == this.processedAtMillis &&
          other.status == this.status &&
          other.extractedTextPreview == this.extractedTextPreview &&
          other.detectedDebtHours == this.detectedDebtHours &&
          other.detectedPaidHours == this.detectedPaidHours &&
          other.detectedPendingHours == this.detectedPendingHours &&
          other.notes == this.notes);
}

class PayrollDocumentsTableCompanion
    extends UpdateCompanion<PayrollDocumentsTableData> {
  final Value<String> id;
  final Value<int> year;
  final Value<int> month;
  final Value<String> source;
  final Value<String?> senderEmail;
  final Value<String?> gmailMessageId;
  final Value<String?> gmailAttachmentId;
  final Value<String> fileName;
  final Value<String?> localPath;
  final Value<String?> fileHash;
  final Value<int> importedAtMillis;
  final Value<int?> processedAtMillis;
  final Value<String> status;
  final Value<String?> extractedTextPreview;
  final Value<double?> detectedDebtHours;
  final Value<double?> detectedPaidHours;
  final Value<double?> detectedPendingHours;
  final Value<String?> notes;
  final Value<int> rowid;
  const PayrollDocumentsTableCompanion({
    this.id = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.source = const Value.absent(),
    this.senderEmail = const Value.absent(),
    this.gmailMessageId = const Value.absent(),
    this.gmailAttachmentId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.importedAtMillis = const Value.absent(),
    this.processedAtMillis = const Value.absent(),
    this.status = const Value.absent(),
    this.extractedTextPreview = const Value.absent(),
    this.detectedDebtHours = const Value.absent(),
    this.detectedPaidHours = const Value.absent(),
    this.detectedPendingHours = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PayrollDocumentsTableCompanion.insert({
    required String id,
    required int year,
    required int month,
    required String source,
    this.senderEmail = const Value.absent(),
    this.gmailMessageId = const Value.absent(),
    this.gmailAttachmentId = const Value.absent(),
    required String fileName,
    this.localPath = const Value.absent(),
    this.fileHash = const Value.absent(),
    required int importedAtMillis,
    this.processedAtMillis = const Value.absent(),
    required String status,
    this.extractedTextPreview = const Value.absent(),
    this.detectedDebtHours = const Value.absent(),
    this.detectedPaidHours = const Value.absent(),
    this.detectedPendingHours = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       year = Value(year),
       month = Value(month),
       source = Value(source),
       fileName = Value(fileName),
       importedAtMillis = Value(importedAtMillis),
       status = Value(status);
  static Insertable<PayrollDocumentsTableData> custom({
    Expression<String>? id,
    Expression<int>? year,
    Expression<int>? month,
    Expression<String>? source,
    Expression<String>? senderEmail,
    Expression<String>? gmailMessageId,
    Expression<String>? gmailAttachmentId,
    Expression<String>? fileName,
    Expression<String>? localPath,
    Expression<String>? fileHash,
    Expression<int>? importedAtMillis,
    Expression<int>? processedAtMillis,
    Expression<String>? status,
    Expression<String>? extractedTextPreview,
    Expression<double>? detectedDebtHours,
    Expression<double>? detectedPaidHours,
    Expression<double>? detectedPendingHours,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (source != null) 'source': source,
      if (senderEmail != null) 'sender_email': senderEmail,
      if (gmailMessageId != null) 'gmail_message_id': gmailMessageId,
      if (gmailAttachmentId != null) 'gmail_attachment_id': gmailAttachmentId,
      if (fileName != null) 'file_name': fileName,
      if (localPath != null) 'local_path': localPath,
      if (fileHash != null) 'file_hash': fileHash,
      if (importedAtMillis != null) 'imported_at_millis': importedAtMillis,
      if (processedAtMillis != null) 'processed_at_millis': processedAtMillis,
      if (status != null) 'status': status,
      if (extractedTextPreview != null)
        'extracted_text_preview': extractedTextPreview,
      if (detectedDebtHours != null) 'detected_debt_hours': detectedDebtHours,
      if (detectedPaidHours != null) 'detected_paid_hours': detectedPaidHours,
      if (detectedPendingHours != null)
        'detected_pending_hours': detectedPendingHours,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PayrollDocumentsTableCompanion copyWith({
    Value<String>? id,
    Value<int>? year,
    Value<int>? month,
    Value<String>? source,
    Value<String?>? senderEmail,
    Value<String?>? gmailMessageId,
    Value<String?>? gmailAttachmentId,
    Value<String>? fileName,
    Value<String?>? localPath,
    Value<String?>? fileHash,
    Value<int>? importedAtMillis,
    Value<int?>? processedAtMillis,
    Value<String>? status,
    Value<String?>? extractedTextPreview,
    Value<double?>? detectedDebtHours,
    Value<double?>? detectedPaidHours,
    Value<double?>? detectedPendingHours,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return PayrollDocumentsTableCompanion(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      source: source ?? this.source,
      senderEmail: senderEmail ?? this.senderEmail,
      gmailMessageId: gmailMessageId ?? this.gmailMessageId,
      gmailAttachmentId: gmailAttachmentId ?? this.gmailAttachmentId,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      fileHash: fileHash ?? this.fileHash,
      importedAtMillis: importedAtMillis ?? this.importedAtMillis,
      processedAtMillis: processedAtMillis ?? this.processedAtMillis,
      status: status ?? this.status,
      extractedTextPreview: extractedTextPreview ?? this.extractedTextPreview,
      detectedDebtHours: detectedDebtHours ?? this.detectedDebtHours,
      detectedPaidHours: detectedPaidHours ?? this.detectedPaidHours,
      detectedPendingHours: detectedPendingHours ?? this.detectedPendingHours,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (senderEmail.present) {
      map['sender_email'] = Variable<String>(senderEmail.value);
    }
    if (gmailMessageId.present) {
      map['gmail_message_id'] = Variable<String>(gmailMessageId.value);
    }
    if (gmailAttachmentId.present) {
      map['gmail_attachment_id'] = Variable<String>(gmailAttachmentId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (importedAtMillis.present) {
      map['imported_at_millis'] = Variable<int>(importedAtMillis.value);
    }
    if (processedAtMillis.present) {
      map['processed_at_millis'] = Variable<int>(processedAtMillis.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (extractedTextPreview.present) {
      map['extracted_text_preview'] = Variable<String>(
        extractedTextPreview.value,
      );
    }
    if (detectedDebtHours.present) {
      map['detected_debt_hours'] = Variable<double>(detectedDebtHours.value);
    }
    if (detectedPaidHours.present) {
      map['detected_paid_hours'] = Variable<double>(detectedPaidHours.value);
    }
    if (detectedPendingHours.present) {
      map['detected_pending_hours'] = Variable<double>(
        detectedPendingHours.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PayrollDocumentsTableCompanion(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('source: $source, ')
          ..write('senderEmail: $senderEmail, ')
          ..write('gmailMessageId: $gmailMessageId, ')
          ..write('gmailAttachmentId: $gmailAttachmentId, ')
          ..write('fileName: $fileName, ')
          ..write('localPath: $localPath, ')
          ..write('fileHash: $fileHash, ')
          ..write('importedAtMillis: $importedAtMillis, ')
          ..write('processedAtMillis: $processedAtMillis, ')
          ..write('status: $status, ')
          ..write('extractedTextPreview: $extractedTextPreview, ')
          ..write('detectedDebtHours: $detectedDebtHours, ')
          ..write('detectedPaidHours: $detectedPaidHours, ')
          ..write('detectedPendingHours: $detectedPendingHours, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTableTable extends UserSettingsTable
    with TableInfo<$UserSettingsTableTable, UserSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pdfPasswordSavedMeta = const VerificationMeta(
    'pdfPasswordSaved',
  );
  @override
  late final GeneratedColumn<bool> pdfPasswordSaved = GeneratedColumn<bool>(
    'pdf_password_saved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pdf_password_saved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _defaultPercentagesJsonMeta =
      const VerificationMeta('defaultPercentagesJson');
  @override
  late final GeneratedColumn<String> defaultPercentagesJson =
      GeneratedColumn<String>(
        'default_percentages_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _gmailSenderFilterMeta = const VerificationMeta(
    'gmailSenderFilter',
  );
  @override
  late final GeneratedColumn<String> gmailSenderFilter =
      GeneratedColumn<String>(
        'gmail_sender_filter',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _autoSyncEnabledMeta = const VerificationMeta(
    'autoSyncEnabled',
  );
  @override
  late final GeneratedColumn<bool> autoSyncEnabled = GeneratedColumn<bool>(
    'auto_sync_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_sync_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMillisMeta = const VerificationMeta(
    'createdAtMillis',
  );
  @override
  late final GeneratedColumn<int> createdAtMillis = GeneratedColumn<int>(
    'created_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMillisMeta = const VerificationMeta(
    'updatedAtMillis',
  );
  @override
  late final GeneratedColumn<int> updatedAtMillis = GeneratedColumn<int>(
    'updated_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pdfPasswordSaved,
    defaultPercentagesJson,
    gmailSenderFilter,
    autoSyncEnabled,
    createdAtMillis,
    updatedAtMillis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pdf_password_saved')) {
      context.handle(
        _pdfPasswordSavedMeta,
        pdfPasswordSaved.isAcceptableOrUnknown(
          data['pdf_password_saved']!,
          _pdfPasswordSavedMeta,
        ),
      );
    }
    if (data.containsKey('default_percentages_json')) {
      context.handle(
        _defaultPercentagesJsonMeta,
        defaultPercentagesJson.isAcceptableOrUnknown(
          data['default_percentages_json']!,
          _defaultPercentagesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultPercentagesJsonMeta);
    }
    if (data.containsKey('gmail_sender_filter')) {
      context.handle(
        _gmailSenderFilterMeta,
        gmailSenderFilter.isAcceptableOrUnknown(
          data['gmail_sender_filter']!,
          _gmailSenderFilterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gmailSenderFilterMeta);
    }
    if (data.containsKey('auto_sync_enabled')) {
      context.handle(
        _autoSyncEnabledMeta,
        autoSyncEnabled.isAcceptableOrUnknown(
          data['auto_sync_enabled']!,
          _autoSyncEnabledMeta,
        ),
      );
    }
    if (data.containsKey('created_at_millis')) {
      context.handle(
        _createdAtMillisMeta,
        createdAtMillis.isAcceptableOrUnknown(
          data['created_at_millis']!,
          _createdAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMillisMeta);
    }
    if (data.containsKey('updated_at_millis')) {
      context.handle(
        _updatedAtMillisMeta,
        updatedAtMillis.isAcceptableOrUnknown(
          data['updated_at_millis']!,
          _updatedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSettingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      pdfPasswordSaved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pdf_password_saved'],
      )!,
      defaultPercentagesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_percentages_json'],
      )!,
      gmailSenderFilter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gmail_sender_filter'],
      )!,
      autoSyncEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_sync_enabled'],
      )!,
      createdAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_millis'],
      )!,
      updatedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_millis'],
      )!,
    );
  }

  @override
  $UserSettingsTableTable createAlias(String alias) {
    return $UserSettingsTableTable(attachedDatabase, alias);
  }
}

class UserSettingsTableData extends DataClass
    implements Insertable<UserSettingsTableData> {
  final int id;
  final bool pdfPasswordSaved;
  final String defaultPercentagesJson;
  final String gmailSenderFilter;
  final bool autoSyncEnabled;
  final int createdAtMillis;
  final int updatedAtMillis;
  const UserSettingsTableData({
    required this.id,
    required this.pdfPasswordSaved,
    required this.defaultPercentagesJson,
    required this.gmailSenderFilter,
    required this.autoSyncEnabled,
    required this.createdAtMillis,
    required this.updatedAtMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pdf_password_saved'] = Variable<bool>(pdfPasswordSaved);
    map['default_percentages_json'] = Variable<String>(defaultPercentagesJson);
    map['gmail_sender_filter'] = Variable<String>(gmailSenderFilter);
    map['auto_sync_enabled'] = Variable<bool>(autoSyncEnabled);
    map['created_at_millis'] = Variable<int>(createdAtMillis);
    map['updated_at_millis'] = Variable<int>(updatedAtMillis);
    return map;
  }

  UserSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsTableCompanion(
      id: Value(id),
      pdfPasswordSaved: Value(pdfPasswordSaved),
      defaultPercentagesJson: Value(defaultPercentagesJson),
      gmailSenderFilter: Value(gmailSenderFilter),
      autoSyncEnabled: Value(autoSyncEnabled),
      createdAtMillis: Value(createdAtMillis),
      updatedAtMillis: Value(updatedAtMillis),
    );
  }

  factory UserSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      pdfPasswordSaved: serializer.fromJson<bool>(json['pdfPasswordSaved']),
      defaultPercentagesJson: serializer.fromJson<String>(
        json['defaultPercentagesJson'],
      ),
      gmailSenderFilter: serializer.fromJson<String>(json['gmailSenderFilter']),
      autoSyncEnabled: serializer.fromJson<bool>(json['autoSyncEnabled']),
      createdAtMillis: serializer.fromJson<int>(json['createdAtMillis']),
      updatedAtMillis: serializer.fromJson<int>(json['updatedAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pdfPasswordSaved': serializer.toJson<bool>(pdfPasswordSaved),
      'defaultPercentagesJson': serializer.toJson<String>(
        defaultPercentagesJson,
      ),
      'gmailSenderFilter': serializer.toJson<String>(gmailSenderFilter),
      'autoSyncEnabled': serializer.toJson<bool>(autoSyncEnabled),
      'createdAtMillis': serializer.toJson<int>(createdAtMillis),
      'updatedAtMillis': serializer.toJson<int>(updatedAtMillis),
    };
  }

  UserSettingsTableData copyWith({
    int? id,
    bool? pdfPasswordSaved,
    String? defaultPercentagesJson,
    String? gmailSenderFilter,
    bool? autoSyncEnabled,
    int? createdAtMillis,
    int? updatedAtMillis,
  }) => UserSettingsTableData(
    id: id ?? this.id,
    pdfPasswordSaved: pdfPasswordSaved ?? this.pdfPasswordSaved,
    defaultPercentagesJson:
        defaultPercentagesJson ?? this.defaultPercentagesJson,
    gmailSenderFilter: gmailSenderFilter ?? this.gmailSenderFilter,
    autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
    createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
  );
  UserSettingsTableData copyWithCompanion(UserSettingsTableCompanion data) {
    return UserSettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      pdfPasswordSaved: data.pdfPasswordSaved.present
          ? data.pdfPasswordSaved.value
          : this.pdfPasswordSaved,
      defaultPercentagesJson: data.defaultPercentagesJson.present
          ? data.defaultPercentagesJson.value
          : this.defaultPercentagesJson,
      gmailSenderFilter: data.gmailSenderFilter.present
          ? data.gmailSenderFilter.value
          : this.gmailSenderFilter,
      autoSyncEnabled: data.autoSyncEnabled.present
          ? data.autoSyncEnabled.value
          : this.autoSyncEnabled,
      createdAtMillis: data.createdAtMillis.present
          ? data.createdAtMillis.value
          : this.createdAtMillis,
      updatedAtMillis: data.updatedAtMillis.present
          ? data.updatedAtMillis.value
          : this.updatedAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsTableData(')
          ..write('id: $id, ')
          ..write('pdfPasswordSaved: $pdfPasswordSaved, ')
          ..write('defaultPercentagesJson: $defaultPercentagesJson, ')
          ..write('gmailSenderFilter: $gmailSenderFilter, ')
          ..write('autoSyncEnabled: $autoSyncEnabled, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pdfPasswordSaved,
    defaultPercentagesJson,
    gmailSenderFilter,
    autoSyncEnabled,
    createdAtMillis,
    updatedAtMillis,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSettingsTableData &&
          other.id == this.id &&
          other.pdfPasswordSaved == this.pdfPasswordSaved &&
          other.defaultPercentagesJson == this.defaultPercentagesJson &&
          other.gmailSenderFilter == this.gmailSenderFilter &&
          other.autoSyncEnabled == this.autoSyncEnabled &&
          other.createdAtMillis == this.createdAtMillis &&
          other.updatedAtMillis == this.updatedAtMillis);
}

class UserSettingsTableCompanion
    extends UpdateCompanion<UserSettingsTableData> {
  final Value<int> id;
  final Value<bool> pdfPasswordSaved;
  final Value<String> defaultPercentagesJson;
  final Value<String> gmailSenderFilter;
  final Value<bool> autoSyncEnabled;
  final Value<int> createdAtMillis;
  final Value<int> updatedAtMillis;
  const UserSettingsTableCompanion({
    this.id = const Value.absent(),
    this.pdfPasswordSaved = const Value.absent(),
    this.defaultPercentagesJson = const Value.absent(),
    this.gmailSenderFilter = const Value.absent(),
    this.autoSyncEnabled = const Value.absent(),
    this.createdAtMillis = const Value.absent(),
    this.updatedAtMillis = const Value.absent(),
  });
  UserSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.pdfPasswordSaved = const Value.absent(),
    required String defaultPercentagesJson,
    required String gmailSenderFilter,
    this.autoSyncEnabled = const Value.absent(),
    required int createdAtMillis,
    required int updatedAtMillis,
  }) : defaultPercentagesJson = Value(defaultPercentagesJson),
       gmailSenderFilter = Value(gmailSenderFilter),
       createdAtMillis = Value(createdAtMillis),
       updatedAtMillis = Value(updatedAtMillis);
  static Insertable<UserSettingsTableData> custom({
    Expression<int>? id,
    Expression<bool>? pdfPasswordSaved,
    Expression<String>? defaultPercentagesJson,
    Expression<String>? gmailSenderFilter,
    Expression<bool>? autoSyncEnabled,
    Expression<int>? createdAtMillis,
    Expression<int>? updatedAtMillis,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pdfPasswordSaved != null) 'pdf_password_saved': pdfPasswordSaved,
      if (defaultPercentagesJson != null)
        'default_percentages_json': defaultPercentagesJson,
      if (gmailSenderFilter != null) 'gmail_sender_filter': gmailSenderFilter,
      if (autoSyncEnabled != null) 'auto_sync_enabled': autoSyncEnabled,
      if (createdAtMillis != null) 'created_at_millis': createdAtMillis,
      if (updatedAtMillis != null) 'updated_at_millis': updatedAtMillis,
    });
  }

  UserSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<bool>? pdfPasswordSaved,
    Value<String>? defaultPercentagesJson,
    Value<String>? gmailSenderFilter,
    Value<bool>? autoSyncEnabled,
    Value<int>? createdAtMillis,
    Value<int>? updatedAtMillis,
  }) {
    return UserSettingsTableCompanion(
      id: id ?? this.id,
      pdfPasswordSaved: pdfPasswordSaved ?? this.pdfPasswordSaved,
      defaultPercentagesJson:
          defaultPercentagesJson ?? this.defaultPercentagesJson,
      gmailSenderFilter: gmailSenderFilter ?? this.gmailSenderFilter,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pdfPasswordSaved.present) {
      map['pdf_password_saved'] = Variable<bool>(pdfPasswordSaved.value);
    }
    if (defaultPercentagesJson.present) {
      map['default_percentages_json'] = Variable<String>(
        defaultPercentagesJson.value,
      );
    }
    if (gmailSenderFilter.present) {
      map['gmail_sender_filter'] = Variable<String>(gmailSenderFilter.value);
    }
    if (autoSyncEnabled.present) {
      map['auto_sync_enabled'] = Variable<bool>(autoSyncEnabled.value);
    }
    if (createdAtMillis.present) {
      map['created_at_millis'] = Variable<int>(createdAtMillis.value);
    }
    if (updatedAtMillis.present) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('pdfPasswordSaved: $pdfPasswordSaved, ')
          ..write('defaultPercentagesJson: $defaultPercentagesJson, ')
          ..write('gmailSenderFilter: $gmailSenderFilter, ')
          ..write('autoSyncEnabled: $autoSyncEnabled, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HourPaymentsTableTable hourPaymentsTable =
      $HourPaymentsTableTable(this);
  late final $HourBalancesTableTable hourBalancesTable =
      $HourBalancesTableTable(this);
  late final $PayrollDocumentsTableTable payrollDocumentsTable =
      $PayrollDocumentsTableTable(this);
  late final $UserSettingsTableTable userSettingsTable =
      $UserSettingsTableTable(this);
  late final HourPaymentsDao hourPaymentsDao = HourPaymentsDao(
    this as AppDatabase,
  );
  late final HourBalancesDao hourBalancesDao = HourBalancesDao(
    this as AppDatabase,
  );
  late final PayrollDocumentsDao payrollDocumentsDao = PayrollDocumentsDao(
    this as AppDatabase,
  );
  late final UserSettingsDao userSettingsDao = UserSettingsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    hourPaymentsTable,
    hourBalancesTable,
    payrollDocumentsTable,
    userSettingsTable,
  ];
}

typedef $$HourPaymentsTableTableCreateCompanionBuilder =
    HourPaymentsTableCompanion Function({
      required String id,
      required int dateMillis,
      required double hours,
      required double percentage,
      required double equivalentHours,
      Value<String?> observation,
      required int payrollMonth,
      required int payrollYear,
      required int createdAtMillis,
      Value<int?> updatedAtMillis,
      Value<int> rowid,
    });
typedef $$HourPaymentsTableTableUpdateCompanionBuilder =
    HourPaymentsTableCompanion Function({
      Value<String> id,
      Value<int> dateMillis,
      Value<double> hours,
      Value<double> percentage,
      Value<double> equivalentHours,
      Value<String?> observation,
      Value<int> payrollMonth,
      Value<int> payrollYear,
      Value<int> createdAtMillis,
      Value<int?> updatedAtMillis,
      Value<int> rowid,
    });

class $$HourPaymentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $HourPaymentsTableTable> {
  $$HourPaymentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateMillis => $composableBuilder(
    column: $table.dateMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get equivalentHours => $composableBuilder(
    column: $table.equivalentHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observation => $composableBuilder(
    column: $table.observation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payrollMonth => $composableBuilder(
    column: $table.payrollMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payrollYear => $composableBuilder(
    column: $table.payrollYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HourPaymentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $HourPaymentsTableTable> {
  $$HourPaymentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateMillis => $composableBuilder(
    column: $table.dateMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get equivalentHours => $composableBuilder(
    column: $table.equivalentHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observation => $composableBuilder(
    column: $table.observation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payrollMonth => $composableBuilder(
    column: $table.payrollMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payrollYear => $composableBuilder(
    column: $table.payrollYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HourPaymentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $HourPaymentsTableTable> {
  $$HourPaymentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dateMillis => $composableBuilder(
    column: $table.dateMillis,
    builder: (column) => column,
  );

  GeneratedColumn<double> get hours =>
      $composableBuilder(column: $table.hours, builder: (column) => column);

  GeneratedColumn<double> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get equivalentHours => $composableBuilder(
    column: $table.equivalentHours,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observation => $composableBuilder(
    column: $table.observation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get payrollMonth => $composableBuilder(
    column: $table.payrollMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get payrollYear => $composableBuilder(
    column: $table.payrollYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => column,
  );
}

class $$HourPaymentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HourPaymentsTableTable,
          HourPaymentsTableData,
          $$HourPaymentsTableTableFilterComposer,
          $$HourPaymentsTableTableOrderingComposer,
          $$HourPaymentsTableTableAnnotationComposer,
          $$HourPaymentsTableTableCreateCompanionBuilder,
          $$HourPaymentsTableTableUpdateCompanionBuilder,
          (
            HourPaymentsTableData,
            BaseReferences<
              _$AppDatabase,
              $HourPaymentsTableTable,
              HourPaymentsTableData
            >,
          ),
          HourPaymentsTableData,
          PrefetchHooks Function()
        > {
  $$HourPaymentsTableTableTableManager(
    _$AppDatabase db,
    $HourPaymentsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HourPaymentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HourPaymentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HourPaymentsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> dateMillis = const Value.absent(),
                Value<double> hours = const Value.absent(),
                Value<double> percentage = const Value.absent(),
                Value<double> equivalentHours = const Value.absent(),
                Value<String?> observation = const Value.absent(),
                Value<int> payrollMonth = const Value.absent(),
                Value<int> payrollYear = const Value.absent(),
                Value<int> createdAtMillis = const Value.absent(),
                Value<int?> updatedAtMillis = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HourPaymentsTableCompanion(
                id: id,
                dateMillis: dateMillis,
                hours: hours,
                percentage: percentage,
                equivalentHours: equivalentHours,
                observation: observation,
                payrollMonth: payrollMonth,
                payrollYear: payrollYear,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int dateMillis,
                required double hours,
                required double percentage,
                required double equivalentHours,
                Value<String?> observation = const Value.absent(),
                required int payrollMonth,
                required int payrollYear,
                required int createdAtMillis,
                Value<int?> updatedAtMillis = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HourPaymentsTableCompanion.insert(
                id: id,
                dateMillis: dateMillis,
                hours: hours,
                percentage: percentage,
                equivalentHours: equivalentHours,
                observation: observation,
                payrollMonth: payrollMonth,
                payrollYear: payrollYear,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HourPaymentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HourPaymentsTableTable,
      HourPaymentsTableData,
      $$HourPaymentsTableTableFilterComposer,
      $$HourPaymentsTableTableOrderingComposer,
      $$HourPaymentsTableTableAnnotationComposer,
      $$HourPaymentsTableTableCreateCompanionBuilder,
      $$HourPaymentsTableTableUpdateCompanionBuilder,
      (
        HourPaymentsTableData,
        BaseReferences<
          _$AppDatabase,
          $HourPaymentsTableTable,
          HourPaymentsTableData
        >,
      ),
      HourPaymentsTableData,
      PrefetchHooks Function()
    >;
typedef $$HourBalancesTableTableCreateCompanionBuilder =
    HourBalancesTableCompanion Function({
      required int year,
      required int month,
      required double totalDebtHours,
      required double totalPaidEquivalentHours,
      required double pendingHours,
      required double overtimeHours,
      required String status,
      required int calculatedAtMillis,
      Value<int> rowid,
    });
typedef $$HourBalancesTableTableUpdateCompanionBuilder =
    HourBalancesTableCompanion Function({
      Value<int> year,
      Value<int> month,
      Value<double> totalDebtHours,
      Value<double> totalPaidEquivalentHours,
      Value<double> pendingHours,
      Value<double> overtimeHours,
      Value<String> status,
      Value<int> calculatedAtMillis,
      Value<int> rowid,
    });

class $$HourBalancesTableTableFilterComposer
    extends Composer<_$AppDatabase, $HourBalancesTableTable> {
  $$HourBalancesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDebtHours => $composableBuilder(
    column: $table.totalDebtHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPaidEquivalentHours => $composableBuilder(
    column: $table.totalPaidEquivalentHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pendingHours => $composableBuilder(
    column: $table.pendingHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get overtimeHours => $composableBuilder(
    column: $table.overtimeHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calculatedAtMillis => $composableBuilder(
    column: $table.calculatedAtMillis,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HourBalancesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $HourBalancesTableTable> {
  $$HourBalancesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDebtHours => $composableBuilder(
    column: $table.totalDebtHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPaidEquivalentHours => $composableBuilder(
    column: $table.totalPaidEquivalentHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pendingHours => $composableBuilder(
    column: $table.pendingHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get overtimeHours => $composableBuilder(
    column: $table.overtimeHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calculatedAtMillis => $composableBuilder(
    column: $table.calculatedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HourBalancesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $HourBalancesTableTable> {
  $$HourBalancesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<double> get totalDebtHours => $composableBuilder(
    column: $table.totalDebtHours,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalPaidEquivalentHours => $composableBuilder(
    column: $table.totalPaidEquivalentHours,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pendingHours => $composableBuilder(
    column: $table.pendingHours,
    builder: (column) => column,
  );

  GeneratedColumn<double> get overtimeHours => $composableBuilder(
    column: $table.overtimeHours,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get calculatedAtMillis => $composableBuilder(
    column: $table.calculatedAtMillis,
    builder: (column) => column,
  );
}

class $$HourBalancesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HourBalancesTableTable,
          HourBalancesTableData,
          $$HourBalancesTableTableFilterComposer,
          $$HourBalancesTableTableOrderingComposer,
          $$HourBalancesTableTableAnnotationComposer,
          $$HourBalancesTableTableCreateCompanionBuilder,
          $$HourBalancesTableTableUpdateCompanionBuilder,
          (
            HourBalancesTableData,
            BaseReferences<
              _$AppDatabase,
              $HourBalancesTableTable,
              HourBalancesTableData
            >,
          ),
          HourBalancesTableData,
          PrefetchHooks Function()
        > {
  $$HourBalancesTableTableTableManager(
    _$AppDatabase db,
    $HourBalancesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HourBalancesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HourBalancesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HourBalancesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> year = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<double> totalDebtHours = const Value.absent(),
                Value<double> totalPaidEquivalentHours = const Value.absent(),
                Value<double> pendingHours = const Value.absent(),
                Value<double> overtimeHours = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> calculatedAtMillis = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HourBalancesTableCompanion(
                year: year,
                month: month,
                totalDebtHours: totalDebtHours,
                totalPaidEquivalentHours: totalPaidEquivalentHours,
                pendingHours: pendingHours,
                overtimeHours: overtimeHours,
                status: status,
                calculatedAtMillis: calculatedAtMillis,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int year,
                required int month,
                required double totalDebtHours,
                required double totalPaidEquivalentHours,
                required double pendingHours,
                required double overtimeHours,
                required String status,
                required int calculatedAtMillis,
                Value<int> rowid = const Value.absent(),
              }) => HourBalancesTableCompanion.insert(
                year: year,
                month: month,
                totalDebtHours: totalDebtHours,
                totalPaidEquivalentHours: totalPaidEquivalentHours,
                pendingHours: pendingHours,
                overtimeHours: overtimeHours,
                status: status,
                calculatedAtMillis: calculatedAtMillis,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HourBalancesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HourBalancesTableTable,
      HourBalancesTableData,
      $$HourBalancesTableTableFilterComposer,
      $$HourBalancesTableTableOrderingComposer,
      $$HourBalancesTableTableAnnotationComposer,
      $$HourBalancesTableTableCreateCompanionBuilder,
      $$HourBalancesTableTableUpdateCompanionBuilder,
      (
        HourBalancesTableData,
        BaseReferences<
          _$AppDatabase,
          $HourBalancesTableTable,
          HourBalancesTableData
        >,
      ),
      HourBalancesTableData,
      PrefetchHooks Function()
    >;
typedef $$PayrollDocumentsTableTableCreateCompanionBuilder =
    PayrollDocumentsTableCompanion Function({
      required String id,
      required int year,
      required int month,
      required String source,
      Value<String?> senderEmail,
      Value<String?> gmailMessageId,
      Value<String?> gmailAttachmentId,
      required String fileName,
      Value<String?> localPath,
      Value<String?> fileHash,
      required int importedAtMillis,
      Value<int?> processedAtMillis,
      required String status,
      Value<String?> extractedTextPreview,
      Value<double?> detectedDebtHours,
      Value<double?> detectedPaidHours,
      Value<double?> detectedPendingHours,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$PayrollDocumentsTableTableUpdateCompanionBuilder =
    PayrollDocumentsTableCompanion Function({
      Value<String> id,
      Value<int> year,
      Value<int> month,
      Value<String> source,
      Value<String?> senderEmail,
      Value<String?> gmailMessageId,
      Value<String?> gmailAttachmentId,
      Value<String> fileName,
      Value<String?> localPath,
      Value<String?> fileHash,
      Value<int> importedAtMillis,
      Value<int?> processedAtMillis,
      Value<String> status,
      Value<String?> extractedTextPreview,
      Value<double?> detectedDebtHours,
      Value<double?> detectedPaidHours,
      Value<double?> detectedPendingHours,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$PayrollDocumentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PayrollDocumentsTableTable> {
  $$PayrollDocumentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderEmail => $composableBuilder(
    column: $table.senderEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gmailMessageId => $composableBuilder(
    column: $table.gmailMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gmailAttachmentId => $composableBuilder(
    column: $table.gmailAttachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importedAtMillis => $composableBuilder(
    column: $table.importedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get processedAtMillis => $composableBuilder(
    column: $table.processedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractedTextPreview => $composableBuilder(
    column: $table.extractedTextPreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get detectedDebtHours => $composableBuilder(
    column: $table.detectedDebtHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get detectedPaidHours => $composableBuilder(
    column: $table.detectedPaidHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get detectedPendingHours => $composableBuilder(
    column: $table.detectedPendingHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PayrollDocumentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PayrollDocumentsTableTable> {
  $$PayrollDocumentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderEmail => $composableBuilder(
    column: $table.senderEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gmailMessageId => $composableBuilder(
    column: $table.gmailMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gmailAttachmentId => $composableBuilder(
    column: $table.gmailAttachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importedAtMillis => $composableBuilder(
    column: $table.importedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get processedAtMillis => $composableBuilder(
    column: $table.processedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractedTextPreview => $composableBuilder(
    column: $table.extractedTextPreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get detectedDebtHours => $composableBuilder(
    column: $table.detectedDebtHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get detectedPaidHours => $composableBuilder(
    column: $table.detectedPaidHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get detectedPendingHours => $composableBuilder(
    column: $table.detectedPendingHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PayrollDocumentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PayrollDocumentsTableTable> {
  $$PayrollDocumentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get senderEmail => $composableBuilder(
    column: $table.senderEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gmailMessageId => $composableBuilder(
    column: $table.gmailMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gmailAttachmentId => $composableBuilder(
    column: $table.gmailAttachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<int> get importedAtMillis => $composableBuilder(
    column: $table.importedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get processedAtMillis => $composableBuilder(
    column: $table.processedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get extractedTextPreview => $composableBuilder(
    column: $table.extractedTextPreview,
    builder: (column) => column,
  );

  GeneratedColumn<double> get detectedDebtHours => $composableBuilder(
    column: $table.detectedDebtHours,
    builder: (column) => column,
  );

  GeneratedColumn<double> get detectedPaidHours => $composableBuilder(
    column: $table.detectedPaidHours,
    builder: (column) => column,
  );

  GeneratedColumn<double> get detectedPendingHours => $composableBuilder(
    column: $table.detectedPendingHours,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$PayrollDocumentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PayrollDocumentsTableTable,
          PayrollDocumentsTableData,
          $$PayrollDocumentsTableTableFilterComposer,
          $$PayrollDocumentsTableTableOrderingComposer,
          $$PayrollDocumentsTableTableAnnotationComposer,
          $$PayrollDocumentsTableTableCreateCompanionBuilder,
          $$PayrollDocumentsTableTableUpdateCompanionBuilder,
          (
            PayrollDocumentsTableData,
            BaseReferences<
              _$AppDatabase,
              $PayrollDocumentsTableTable,
              PayrollDocumentsTableData
            >,
          ),
          PayrollDocumentsTableData,
          PrefetchHooks Function()
        > {
  $$PayrollDocumentsTableTableTableManager(
    _$AppDatabase db,
    $PayrollDocumentsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PayrollDocumentsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PayrollDocumentsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PayrollDocumentsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> senderEmail = const Value.absent(),
                Value<String?> gmailMessageId = const Value.absent(),
                Value<String?> gmailAttachmentId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> fileHash = const Value.absent(),
                Value<int> importedAtMillis = const Value.absent(),
                Value<int?> processedAtMillis = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> extractedTextPreview = const Value.absent(),
                Value<double?> detectedDebtHours = const Value.absent(),
                Value<double?> detectedPaidHours = const Value.absent(),
                Value<double?> detectedPendingHours = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PayrollDocumentsTableCompanion(
                id: id,
                year: year,
                month: month,
                source: source,
                senderEmail: senderEmail,
                gmailMessageId: gmailMessageId,
                gmailAttachmentId: gmailAttachmentId,
                fileName: fileName,
                localPath: localPath,
                fileHash: fileHash,
                importedAtMillis: importedAtMillis,
                processedAtMillis: processedAtMillis,
                status: status,
                extractedTextPreview: extractedTextPreview,
                detectedDebtHours: detectedDebtHours,
                detectedPaidHours: detectedPaidHours,
                detectedPendingHours: detectedPendingHours,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int year,
                required int month,
                required String source,
                Value<String?> senderEmail = const Value.absent(),
                Value<String?> gmailMessageId = const Value.absent(),
                Value<String?> gmailAttachmentId = const Value.absent(),
                required String fileName,
                Value<String?> localPath = const Value.absent(),
                Value<String?> fileHash = const Value.absent(),
                required int importedAtMillis,
                Value<int?> processedAtMillis = const Value.absent(),
                required String status,
                Value<String?> extractedTextPreview = const Value.absent(),
                Value<double?> detectedDebtHours = const Value.absent(),
                Value<double?> detectedPaidHours = const Value.absent(),
                Value<double?> detectedPendingHours = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PayrollDocumentsTableCompanion.insert(
                id: id,
                year: year,
                month: month,
                source: source,
                senderEmail: senderEmail,
                gmailMessageId: gmailMessageId,
                gmailAttachmentId: gmailAttachmentId,
                fileName: fileName,
                localPath: localPath,
                fileHash: fileHash,
                importedAtMillis: importedAtMillis,
                processedAtMillis: processedAtMillis,
                status: status,
                extractedTextPreview: extractedTextPreview,
                detectedDebtHours: detectedDebtHours,
                detectedPaidHours: detectedPaidHours,
                detectedPendingHours: detectedPendingHours,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PayrollDocumentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PayrollDocumentsTableTable,
      PayrollDocumentsTableData,
      $$PayrollDocumentsTableTableFilterComposer,
      $$PayrollDocumentsTableTableOrderingComposer,
      $$PayrollDocumentsTableTableAnnotationComposer,
      $$PayrollDocumentsTableTableCreateCompanionBuilder,
      $$PayrollDocumentsTableTableUpdateCompanionBuilder,
      (
        PayrollDocumentsTableData,
        BaseReferences<
          _$AppDatabase,
          $PayrollDocumentsTableTable,
          PayrollDocumentsTableData
        >,
      ),
      PayrollDocumentsTableData,
      PrefetchHooks Function()
    >;
typedef $$UserSettingsTableTableCreateCompanionBuilder =
    UserSettingsTableCompanion Function({
      Value<int> id,
      Value<bool> pdfPasswordSaved,
      required String defaultPercentagesJson,
      required String gmailSenderFilter,
      Value<bool> autoSyncEnabled,
      required int createdAtMillis,
      required int updatedAtMillis,
    });
typedef $$UserSettingsTableTableUpdateCompanionBuilder =
    UserSettingsTableCompanion Function({
      Value<int> id,
      Value<bool> pdfPasswordSaved,
      Value<String> defaultPercentagesJson,
      Value<String> gmailSenderFilter,
      Value<bool> autoSyncEnabled,
      Value<int> createdAtMillis,
      Value<int> updatedAtMillis,
    });

class $$UserSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pdfPasswordSaved => $composableBuilder(
    column: $table.pdfPasswordSaved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultPercentagesJson => $composableBuilder(
    column: $table.defaultPercentagesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gmailSenderFilter => $composableBuilder(
    column: $table.gmailSenderFilter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoSyncEnabled => $composableBuilder(
    column: $table.autoSyncEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pdfPasswordSaved => $composableBuilder(
    column: $table.pdfPasswordSaved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultPercentagesJson => $composableBuilder(
    column: $table.defaultPercentagesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gmailSenderFilter => $composableBuilder(
    column: $table.gmailSenderFilter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoSyncEnabled => $composableBuilder(
    column: $table.autoSyncEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get pdfPasswordSaved => $composableBuilder(
    column: $table.pdfPasswordSaved,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultPercentagesJson => $composableBuilder(
    column: $table.defaultPercentagesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gmailSenderFilter => $composableBuilder(
    column: $table.gmailSenderFilter,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoSyncEnabled => $composableBuilder(
    column: $table.autoSyncEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => column,
  );
}

class $$UserSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsTableTable,
          UserSettingsTableData,
          $$UserSettingsTableTableFilterComposer,
          $$UserSettingsTableTableOrderingComposer,
          $$UserSettingsTableTableAnnotationComposer,
          $$UserSettingsTableTableCreateCompanionBuilder,
          $$UserSettingsTableTableUpdateCompanionBuilder,
          (
            UserSettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $UserSettingsTableTable,
              UserSettingsTableData
            >,
          ),
          UserSettingsTableData,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableTableManager(
    _$AppDatabase db,
    $UserSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> pdfPasswordSaved = const Value.absent(),
                Value<String> defaultPercentagesJson = const Value.absent(),
                Value<String> gmailSenderFilter = const Value.absent(),
                Value<bool> autoSyncEnabled = const Value.absent(),
                Value<int> createdAtMillis = const Value.absent(),
                Value<int> updatedAtMillis = const Value.absent(),
              }) => UserSettingsTableCompanion(
                id: id,
                pdfPasswordSaved: pdfPasswordSaved,
                defaultPercentagesJson: defaultPercentagesJson,
                gmailSenderFilter: gmailSenderFilter,
                autoSyncEnabled: autoSyncEnabled,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> pdfPasswordSaved = const Value.absent(),
                required String defaultPercentagesJson,
                required String gmailSenderFilter,
                Value<bool> autoSyncEnabled = const Value.absent(),
                required int createdAtMillis,
                required int updatedAtMillis,
              }) => UserSettingsTableCompanion.insert(
                id: id,
                pdfPasswordSaved: pdfPasswordSaved,
                defaultPercentagesJson: defaultPercentagesJson,
                gmailSenderFilter: gmailSenderFilter,
                autoSyncEnabled: autoSyncEnabled,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsTableTable,
      UserSettingsTableData,
      $$UserSettingsTableTableFilterComposer,
      $$UserSettingsTableTableOrderingComposer,
      $$UserSettingsTableTableAnnotationComposer,
      $$UserSettingsTableTableCreateCompanionBuilder,
      $$UserSettingsTableTableUpdateCompanionBuilder,
      (
        UserSettingsTableData,
        BaseReferences<
          _$AppDatabase,
          $UserSettingsTableTable,
          UserSettingsTableData
        >,
      ),
      UserSettingsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HourPaymentsTableTableTableManager get hourPaymentsTable =>
      $$HourPaymentsTableTableTableManager(_db, _db.hourPaymentsTable);
  $$HourBalancesTableTableTableManager get hourBalancesTable =>
      $$HourBalancesTableTableTableManager(_db, _db.hourBalancesTable);
  $$PayrollDocumentsTableTableTableManager get payrollDocumentsTable =>
      $$PayrollDocumentsTableTableTableManager(_db, _db.payrollDocumentsTable);
  $$UserSettingsTableTableTableManager get userSettingsTable =>
      $$UserSettingsTableTableTableManager(_db, _db.userSettingsTable);
}
