class PayrollImportResult {
  const PayrollImportResult._({
    required this.success,
    this.duplicated,
    this.message,
    this.createdId,
  });

  factory PayrollImportResult.success({String? createdId}) =>
      PayrollImportResult._(success: true, createdId: createdId);

  factory PayrollImportResult.duplicate(String message) =>
      PayrollImportResult._(success: false, duplicated: true, message: message);

  factory PayrollImportResult.failure(String message) => PayrollImportResult._(
    success: false,
    duplicated: false,
    message: message,
  );

  final bool success;
  final bool? duplicated;
  final String? message;
  final String? createdId;
}
