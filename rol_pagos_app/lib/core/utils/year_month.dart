import 'package:flutter/foundation.dart';

/// Mes de nómina (año/calendario).
///
/// Debe tener [==] y [hashCode] por valor: `Riverpod` usa el parámetro de
/// `.family` como clave de caché; sin esto cada `YearMonth(year: …, month: …)`
/// nuevo equivale a otra entrada y los streams no llegan nunca a `data`
/// (quedan perpetuamente en loading en la UI).
@immutable
class YearMonth {
  const YearMonth({required this.year, required this.month});

  factory YearMonth.fromDate(DateTime date) {
    return YearMonth(year: date.year, month: date.month);
  }

  final int year;
  final int month;

  String get label => '$month/$year';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => 'YearMonth($year-$month)';
}
