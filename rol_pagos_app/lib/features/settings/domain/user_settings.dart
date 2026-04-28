class UserSettings {
  const UserSettings({
    required this.id,
    required this.pdfPasswordSaved,
    required this.defaultPercentages,
    required this.gmailSenderFilter,
    required this.autoSyncEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final bool pdfPasswordSaved;
  final List<double> defaultPercentages;
  final String gmailSenderFilter;
  final bool autoSyncEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
}
