import 'package:intl/intl.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

import '../features/payroll/data/payroll_repository.dart';
import 'gmail_api_service.dart';

class GmailSyncResult {
  const GmailSyncResult({
    required this.imported,
    required this.processed,
    required this.pendingPassword,
    required this.duplicates,
    required this.failed,
  });

  final int imported;
  final int processed;
  final int pendingPassword;
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
    String? pdfPassword,
    int maxMessages = 20,
  }) async {
    final sender = (senderEmail ?? '').trim();
    if (sender.isEmpty) {
      throw StateError(
        'Configura primero el correo del remitente (quien envía el rol). '
        'Si no se define, Gmail puede traer PDFs de cualquier origen.',
      );
    }

    // Requisito del producto: traer SOLO PDFs que provengan del remitente configurado.
    // No aplicamos heurísticas por asunto/nombre porque en muchas empresas los adjuntos
    // tienen nombres numéricos y el asunto no contiene palabras clave.
    final query = [
      'from:$sender',
      'has:attachment',
      'filename:pdf',
    ].join(' ');

    final messages = await _gmailApi.listMessages(
      query: query,
      maxResults: maxMessages,
    );

    var imported = 0;
    var processed = 0;
    var pendingPassword = 0;
    var duplicates = 0;
    var failed = 0;

    for (final message in messages) {
      final messageId = message.id;
      if (messageId == null || messageId.isEmpty) continue;

      final full = await _gmailApi.getMessageFull(messageId);
      final payload = full.payload;
      if (payload == null) continue;

      final messageDate = _resolveMessageDate(full);

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
              ? _defaultFileName(messageDate)
              : att.fileName;

          final result = await _payrollRepository.importGmailPdf(
            pdfBytes: bytes,
            originalFileName: fileName,
            year: messageDate.year,
            month: messageDate.month,
            senderEmail: senderEmail ?? '',
            gmailMessageId: messageId,
            gmailAttachmentId: att.attachmentId,
          );

          if (result.duplicated == true) {
            duplicates++;
          } else if (result.success) {
            imported++;

            final createdId = (result.createdId ?? '').trim();
            if (createdId.isEmpty) {
              continue;
            }
            final payroll = await _payrollRepository.getPayrollById(createdId);
            if (payroll == null) {
              continue;
            }

            final pwd = (pdfPassword ?? '').trim();
            if (pwd.isEmpty) {
              pendingPassword++;
              await _payrollRepository.markPendingPassword(
                payroll: payroll,
                reason:
                    'Pendiente contraseña: guarda la contraseña del PDF y pulsa “Procesar” o vuelve a sincronizar.',
              );
              continue;
            }

            final processedResult = await _payrollRepository.processPayroll(
              payroll: payroll,
              password: pwd,
            );
            if (processedResult.success) {
              processed++;
            } else {
              failed++;
            }
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
      processed: processed,
      pendingPassword: pendingPassword,
      duplicates: duplicates,
      failed: failed,
    );
  }

  DateTime _resolveMessageDate(gmail.Message full) {
    // Preferimos `internalDate` porque es un timestamp confiable del mensaje
    // (y no depende del parsing del header "Date").
    final internal = full.internalDate;
    if (internal != null) {
      final millis = int.tryParse(internal.toString());
      if (millis != null) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    }

    // Fallback: header Date (no siempre parseable de forma universal).
    final headers = full.payload?.headers ?? const <gmail.MessagePartHeader>[];
    final dateHeader = headers
        .where((h) => (h.name ?? '').toLowerCase() == 'date')
        .map((h) => (h.value ?? '').trim())
        .where((v) => v.isNotEmpty)
        .cast<String?>()
        .firstWhere((v) => v != null, orElse: () => null);

    final raw = (dateHeader ?? '').trim();
    if (raw.isNotEmpty) {
      // Intentos comunes. Si falla, usamos "ahora".
      for (final pattern in const [
        'EEE, d MMM yyyy HH:mm:ss Z',
        'EEE, dd MMM yyyy HH:mm:ss Z',
        'd MMM yyyy HH:mm:ss Z',
        'dd MMM yyyy HH:mm:ss Z',
      ]) {
        try {
          return DateFormat(pattern, 'en_US').parseUtc(raw).toLocal();
        } catch (_) {}
      }
    }

    return DateTime.now();
  }

  String _defaultFileName(DateTime messageDate) {
    final fmt = DateFormat('yyyy_MM_dd_HH_mm_ss');
    return 'gmail_${fmt.format(messageDate)}.pdf';
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
