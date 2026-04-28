import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/syncfusion_pdf_extractor_service.dart';
import '../domain/pdf_extractor_service.dart';
import 'payroll_pdf_text_parser.dart';

final pdfExtractorServiceProvider = Provider<PdfExtractorService>((ref) {
  return const SyncfusionPdfExtractorService();
});

final payrollPdfTextParserProvider = Provider<PayrollPdfTextParser>((ref) {
  return const PayrollPdfTextParser();
});
