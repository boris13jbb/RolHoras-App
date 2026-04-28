class HourPayment {
  const HourPayment({
    required this.id,
    required this.date,
    required this.hours,
    required this.percentage,
    required this.equivalentHours,
    required this.createdAt,
    this.observation,
    this.payrollMonth,
    this.payrollYear,
    this.updatedAt,
  });

  final String id;
  final DateTime date;
  final double hours;
  final double percentage;
  final double equivalentHours;
  final String? observation;
  final int? payrollMonth;
  final int? payrollYear;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
