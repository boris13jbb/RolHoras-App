import 'pdf_extraction_result.dart';

abstract class PdfExtractorService {
  Future<PdfExtractionResult> extractText({
    required String filePath,
    required String password,
  });
}
