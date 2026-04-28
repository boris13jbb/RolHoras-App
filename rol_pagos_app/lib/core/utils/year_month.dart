class YearMonth {
  const YearMonth({required this.year, required this.month});

  factory YearMonth.fromDate(DateTime date) {
    return YearMonth(year: date.year, month: date.month);
  }

  final int year;
  final int month;

  String get label => '$month/$year';
}
