enum PayrollDocumentStatus {
  imported,
  pendingPassword,
  processed,
  duplicated,
  failed,
}

class PayrollDocument {
  const PayrollDocument({
    required this.id,
    required this.year,
    required this.month,
    required this.source,
    required this.fileName,
    required this.importedAt,
    required this.status,
    this.senderEmail,
    this.gmailMessageId,
    this.gmailAttachmentId,
    this.localPath,
    this.fileHash,
    this.processedAt,
    this.extractedTextPreview,
    this.detectedDebtHours,
    this.detectedPaidHours,
    this.detectedPendingHours,
    this.notes,
  });

  final String id;
  final int year;
  final int month;
  final String source;
  final String? senderEmail;
  final String? gmailMessageId;
  final String? gmailAttachmentId;
  final String fileName;
  final String? localPath;
  final String? fileHash;
  final DateTime importedAt;
  final DateTime? processedAt;
  final PayrollDocumentStatus status;
  final String? extractedTextPreview;
  final double? detectedDebtHours;
  final double? detectedPaidHours;
  final double? detectedPendingHours;
  final String? notes;
}
