import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import '../../../data/local/app_database.dart';
import '../../../services/hash_service.dart';
import '../../../services/local_file_service.dart';
import '../../pdf_reader/application/payroll_pdf_text_parser.dart';
import '../../pdf_reader/data/syncfusion_pdf_extractor_service.dart';
import '../../pdf_reader/domain/pdf_extractor_service.dart';
import '../domain/payroll_document.dart';
import 'payroll_import_result.dart';

class PayrollRepository {
  PayrollRepository({
    required AppDatabase db,
    HashService? hashService,
    LocalFileService? localFileService,
    PdfExtractorService? pdfExtractor,
    PayrollPdfTextParser? pdfTextParser,
  }) : _db = db,
       _hashService = hashService ?? const HashService(),
       _localFileService = localFileService ?? const LocalFileService(),
       _pdfExtractor = pdfExtractor ?? const SyncfusionPdfExtractorService(),
       _pdfTextParser = pdfTextParser ?? const PayrollPdfTextParser();

  final AppDatabase _db;
  final HashService _hashService;
  final LocalFileService _localFileService;
  final PdfExtractorService _pdfExtractor;
  final PayrollPdfTextParser _pdfTextParser;

  Stream<List<PayrollDocument>> watchPayrolls() {
    return _db.payrollDocumentsDao.watchAll().map(
      (rows) => rows.map(_mapRow).toList(growable: false),
    );
  }

  Future<PayrollDocument?> getPayrollById(String id) async {
    final row = await _db.payrollDocumentsDao.findById(id);
    return row == null ? null : _mapRow(row);
  }

  Future<void> markPendingPassword({
    required PayrollDocument payroll,
    String? reason,
  }) async {
    await _db.payrollDocumentsDao.upsert(
      PayrollDocumentsTableCompanion(
        id: Value(payroll.id),
        year: Value(payroll.year),
        month: Value(payroll.month),
        source: Value(payroll.source),
        fileName: Value(payroll.fileName),
        localPath: Value(payroll.localPath),
        fileHash: Value(payroll.fileHash),
        importedAtMillis: Value(payroll.importedAt.millisecondsSinceEpoch),
        processedAtMillis: const Value.absent(),
        status: Value(PayrollDocumentStatus.pendingPassword.name),
        notes: Value(
          (reason ?? 'Pendiente contraseña para procesar automáticamente.').trim(),
        ),
        senderEmail: Value(payroll.senderEmail),
        gmailMessageId: Value(payroll.gmailMessageId),
        gmailAttachmentId: Value(payroll.gmailAttachmentId),
      ),
    );
  }

  Future<PayrollImportResult> importLocalPdf({
    required String sourcePath,
    required String originalFileName,
    required int year,
    required int month,
  }) async {
    final lowerName = originalFileName.toLowerCase();
    if (!lowerName.endsWith('.pdf')) {
      return PayrollImportResult.failure(
        'El archivo seleccionado no es un PDF.',
      );
    }

    final hash = await _hashService.sha256File(sourcePath);
    final duplicated = await _db.payrollDocumentsDao.findByHash(hash);
    if (duplicated != null) {
      return PayrollImportResult.duplicate(
        'Este rol ya fue importado (duplicado por hash).',
      );
    }

    final safeName = _buildSafeFileName(
      year: year,
      month: month,
      originalFileName: originalFileName,
      hashPrefix: hash.substring(0, 10),
    );
    final localPath = await _localFileService.copyIntoPayrollFolder(
      sourcePath: sourcePath,
      targetFileName: safeName,
    );

    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final createdId = nowMillis.toString();
    await _db.payrollDocumentsDao.upsert(
      PayrollDocumentsTableCompanion.insert(
        id: createdId,
        year: year,
        month: month,
        source: 'local',
        fileName: originalFileName,
        localPath: Value(localPath),
        fileHash: Value(hash),
        importedAtMillis: nowMillis,
        processedAtMillis: const Value.absent(),
        status: PayrollDocumentStatus.imported.name,
        extractedTextPreview: const Value.absent(),
        detectedDebtHours: const Value.absent(),
        detectedPaidHours: const Value.absent(),
        detectedPendingHours: const Value.absent(),
        notes: const Value.absent(),
        senderEmail: const Value.absent(),
        gmailMessageId: const Value.absent(),
        gmailAttachmentId: const Value.absent(),
      ),
    );

    return PayrollImportResult.success(createdId: createdId);
  }

  Future<PayrollImportResult> importGmailPdf({
    required List<int> pdfBytes,
    required String originalFileName,
    required int year,
    required int month,
    required String senderEmail,
    required String gmailMessageId,
    required String gmailAttachmentId,
  }) async {
    final lowerName = originalFileName.toLowerCase();
    if (!lowerName.endsWith('.pdf')) {
      return PayrollImportResult.failure('El adjunto no es un PDF.');
    }

    final existing = await _db.payrollDocumentsDao.findByGmailAttachment(
      messageId: gmailMessageId,
      attachmentId: gmailAttachmentId,
    );
    if (existing != null) {
      return PayrollImportResult.duplicate(
        'Este adjunto ya fue importado (duplicado por Gmail).',
      );
    }

    // Guardamos bytes como archivo local y deduplicamos por hash.
    // Primero escribimos y luego calculamos hash sobre el archivo.
    final now = DateTime.now();
    final tempName = _buildSafeFileName(
      year: year,
      month: month,
      originalFileName: originalFileName,
      hashPrefix: 'temp_${now.millisecondsSinceEpoch}',
    );
    final localPath = await _localFileService.writeBytesIntoPayrollFolder(
      bytes: pdfBytes,
      targetFileName: tempName,
    );

    final hash = await _hashService.sha256File(localPath);
    final duplicated = await _db.payrollDocumentsDao.findByHash(hash);
    if (duplicated != null) {
      try {
        await File(localPath).delete();
      } catch (_) {}
      return PayrollImportResult.duplicate(
        'Este rol ya existe (duplicado por hash).',
      );
    }

    // Renombramos con hash real.
    final safeName = _buildSafeFileName(
      year: year,
      month: month,
      originalFileName: originalFileName,
      hashPrefix: hash.substring(0, 10),
    );
    final finalPath = await _localFileService.copyIntoPayrollFolder(
      sourcePath: localPath,
      targetFileName: safeName,
    );
    try {
      await File(localPath).delete();
    } catch (_) {}

    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final createdId = nowMillis.toString();
    await _db.payrollDocumentsDao.upsert(
      PayrollDocumentsTableCompanion.insert(
        id: createdId,
        year: year,
        month: month,
        source: 'gmail',
        senderEmail: Value(senderEmail),
        gmailMessageId: Value(gmailMessageId),
        gmailAttachmentId: Value(gmailAttachmentId),
        fileName: originalFileName,
        localPath: Value(finalPath),
        fileHash: Value(hash),
        importedAtMillis: nowMillis,
        processedAtMillis: const Value.absent(),
        status: PayrollDocumentStatus.imported.name,
        extractedTextPreview: const Value.absent(),
        detectedDebtHours: const Value.absent(),
        detectedPaidHours: const Value.absent(),
        detectedPendingHours: const Value.absent(),
        notes: const Value.absent(),
      ),
    );

    return PayrollImportResult.success(createdId: createdId);
  }

  Future<PayrollImportResult> processPayroll({
    required PayrollDocument payroll,
    required String password,
  }) async {
    final localPath = payroll.localPath;
    if (localPath == null || localPath.isEmpty) {
      return PayrollImportResult.failure('El rol no tiene ruta local.');
    }

    final extraction = await _pdfExtractor.extractText(
      filePath: localPath,
      password: password,
    );

    if (!extraction.success || extraction.text == null) {
      await _db.payrollDocumentsDao.upsert(
        PayrollDocumentsTableCompanion(
          id: Value(payroll.id),
          year: Value(payroll.year),
          month: Value(payroll.month),
          source: Value(payroll.source),
          fileName: Value(payroll.fileName),
          localPath: Value(localPath),
          fileHash: Value(payroll.fileHash),
          importedAtMillis: Value(payroll.importedAt.millisecondsSinceEpoch),
          processedAtMillis: Value(DateTime.now().millisecondsSinceEpoch),
          status: Value(PayrollDocumentStatus.failed.name),
          notes: Value(extraction.errorMessage),
        ),
      );
      return PayrollImportResult.failure(
        extraction.errorMessage ?? 'Fallo al extraer texto.',
      );
    }

    final text = extraction.text!;
    final preview = text.length <= 600 ? text : text.substring(0, 600);
    final parsed = _pdfTextParser.parse(text);
    final parsedYear = parsed.periodYear;
    final parsedMonth = parsed.periodMonth;
    final finalYear = parsedYear ?? payroll.year;
    final finalMonth = parsedMonth ?? payroll.month;

    await _db.payrollDocumentsDao.upsert(
      PayrollDocumentsTableCompanion(
        id: Value(payroll.id),
        year: Value(finalYear),
        month: Value(finalMonth),
        source: Value(payroll.source),
        fileName: Value(payroll.fileName),
        localPath: Value(localPath),
        fileHash: Value(payroll.fileHash),
        importedAtMillis: Value(payroll.importedAt.millisecondsSinceEpoch),
        processedAtMillis: Value(DateTime.now().millisecondsSinceEpoch),
        status: Value(PayrollDocumentStatus.processed.name),
        extractedTextPreview: Value(preview),
        detectedDebtHours: Value(parsed.debtHours),
        detectedPaidHours: Value(parsed.paidHours),
        detectedPendingHours: Value(parsed.pendingHours),
        notes: const Value.absent(),
      ),
    );

    return PayrollImportResult.success();
  }

  Future<PayrollImportResult> deletePayroll(PayrollDocument payroll) async {
    final localPath = payroll.localPath;
    if (localPath != null && localPath.trim().isNotEmpty) {
      try {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        return PayrollImportResult.failure(
          'No se pudo eliminar el archivo local del rol. Detalle: $e',
        );
      }
    }

    try {
      await _db.payrollDocumentsDao.deleteById(payroll.id);
    } catch (e) {
      return PayrollImportResult.failure(
        'No se pudo eliminar el registro del rol. Detalle: $e',
      );
    }

    return PayrollImportResult.success();
  }

  String _buildSafeFileName({
    required int year,
    required int month,
    required String originalFileName,
    required String hashPrefix,
  }) {
    final base = p.basenameWithoutExtension(originalFileName);
    final sanitizedBase = base
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '')
        .trim()
        .replaceAll(' ', '_');
    final paddedMonth = month.toString().padLeft(2, '0');
    return 'rol_${year}_${paddedMonth}_${sanitizedBase}_$hashPrefix.pdf';
  }

  PayrollDocument _mapRow(PayrollDocumentsTableData row) {
    return PayrollDocument(
      id: row.id,
      year: row.year,
      month: row.month,
      source: row.source,
      senderEmail: row.senderEmail,
      gmailMessageId: row.gmailMessageId,
      gmailAttachmentId: row.gmailAttachmentId,
      fileName: row.fileName,
      localPath: row.localPath,
      fileHash: row.fileHash,
      importedAt: DateTime.fromMillisecondsSinceEpoch(row.importedAtMillis),
      processedAt: row.processedAtMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.processedAtMillis!),
      status: PayrollDocumentStatus.values.byName(row.status),
      extractedTextPreview: row.extractedTextPreview,
      detectedDebtHours: row.detectedDebtHours,
      detectedPaidHours: row.detectedPaidHours,
      detectedPendingHours: row.detectedPendingHours,
      notes: row.notes,
    );
  }
}
