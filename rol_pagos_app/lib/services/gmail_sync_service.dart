import 'package:intl/intl.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

import '../features/payroll/data/payroll_repository.dart';
import 'gmail_api_service.dart';

class GmailSyncResult {
  const GmailSyncResult({
    required this.imported,
    required this.duplicates,
    required this.failed,
  });

  final int imported;
  final int duplicates;
  final int failed;
}

class GmailSyncService {
  GmailSyncService({
    required GmailApiService gmailApi,
    required PayrollRepository payrollRepository,
  }) : _gmailApi = gmailApi,
       _payrollRepository = payrollRepository;

  final GmailApiService _gmailApi;
  final PayrollRepository _payrollRepository;

  /// Sincroniza adjuntos PDF desde Gmail e intenta importarlos al historial local.
  ///
  /// Esta primera versión:
  /// - filtra por remitente (si se entrega) y PDFs adjuntos
  /// - asigna año/mes al actual (fase posterior: detección por nombre o contenido)
  Future<GmailSyncResult> syncPayrollPdfs({
    String? senderEmail,
    int maxMessages = 20,
  }) async {
    final senderPart = (senderEmail == null || senderEmail.trim().isEmpty)
        ? ''
        : 'from:${senderEmail.trim()} ';
    final query = '${senderPart}has:attachment filename:pdf';

    final messages = await _gmailApi.listMessages(
      query: query,
      maxResults: maxMessages,
    );

    var imported = 0;
    var duplicates = 0;
    var failed = 0;

    final now = DateTime.now();
    for (final message in messages) {
      final messageId = message.id;
      if (messageId == null || messageId.isEmpty) continue;

      final full = await _gmailApi.getMessageFull(messageId);
      final payload = full.payload;
      if (payload == null) continue;

      final attachments = _extractPdfAttachments(payload);
      for (final att in attachments) {
        try {
          final bytes = await _gmailApi.downloadAttachmentBytes(
            messageId: messageId,
            attachmentId: att.attachmentId,
          );
          if (bytes.isEmpty) {
            failed++;
            continue;
          }

          final fileName = att.fileName.isEmpty
              ? _defaultFileName(now)
              : att.fileName;

          final result = await _payrollRepository.importGmailPdf(
            pdfBytes: bytes,
            originalFileName: fileName,
            year: now.year,
            month: now.month,
            senderEmail: senderEmail ?? '',
            gmailMessageId: messageId,
            gmailAttachmentId: att.attachmentId,
          );

          if (result.duplicated == true) {
            duplicates++;
          } else if (result.success) {
            imported++;
          } else {
            failed++;
          }
        } catch (_) {
          failed++;
        }
      }
    }

    return GmailSyncResult(
      imported: imported,
      duplicates: duplicates,
      failed: failed,
    );
  }

  String _defaultFileName(DateTime now) {
    final fmt = DateFormat('yyyy_MM_dd_HH_mm_ss');
    return 'gmail_${fmt.format(now)}.pdf';
  }

  List<_PdfAttachmentRef> _extractPdfAttachments(gmail.MessagePart payload) {
    final out = <_PdfAttachmentRef>[];
    void walk(gmail.MessagePart part) {
      final filename = part.filename ?? '';
      final mimeType = part.mimeType ?? '';
      final attachmentId = part.body?.attachmentId ?? '';

      final isPdf =
          filename.toLowerCase().endsWith('.pdf') ||
          mimeType == 'application/pdf';

      if (isPdf && attachmentId.isNotEmpty) {
        out.add(
          _PdfAttachmentRef(fileName: filename, attachmentId: attachmentId),
        );
      }

      final parts = part.parts;
      if (parts != null) {
        for (final child in parts) {
          walk(child);
        }
      }
    }

    walk(payload);
    return out;
  }
}

class _PdfAttachmentRef {
  const _PdfAttachmentRef({required this.fileName, required this.attachmentId});

  final String fileName;
  final String attachmentId;
}
