import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../domain/pdf_extraction_result.dart';
import '../domain/pdf_extractor_service.dart';

class SyncfusionPdfExtractorService implements PdfExtractorService {
  const SyncfusionPdfExtractorService();

  @override
  Future<PdfExtractionResult> extractText({
    required String filePath,
    required String password,
  }) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final pdf = PdfDocument(
        inputBytes: bytes,
        password: password.isEmpty ? null : password,
      );
      final extractor = PdfTextExtractor(pdf);
      final text = extractor.extractText();
      pdf.dispose();

      if (text.trim().isEmpty) {
        return const PdfExtractionResult(
          success: false,
          errorMessage: 'No se encontró texto extraíble en el PDF.',
        );
      }

      return PdfExtractionResult(success: true, text: text);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('password') ||
          msg.contains('encrypted') ||
          msg.contains('encrypt')) {
        return const PdfExtractionResult(
          success: false,
          errorMessage: 'Contraseña incorrecta o PDF protegido.',
        );
      }
      return PdfExtractionResult(
        success: false,
        errorMessage: 'No se pudo leer el PDF: $e',
      );
    }
  }
}
