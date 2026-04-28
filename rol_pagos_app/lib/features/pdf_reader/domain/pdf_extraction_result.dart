class PdfExtractionResult {
  const PdfExtractionResult({
    required this.success,
    this.text,
    this.errorMessage,
  });

  final bool success;
  final String? text;
  final String? errorMessage;
}
