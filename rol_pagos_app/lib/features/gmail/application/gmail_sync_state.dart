class GmailSyncState {
  const GmailSyncState({
    required this.isConfigured,
    required this.isConnected,
    required this.connectedEmail,
    required this.isSyncing,
    required this.lastResultMessage,
    required this.autoSyncEnabled,
    required this.senderFilter,
    required this.gmailPrefsLoaded,
  });

  final bool isConfigured;
  final bool isConnected;
  final String? connectedEmail;
  final bool isSyncing;
  final String? lastResultMessage;
  final bool autoSyncEnabled;
  final String? senderFilter;
  /// `true` tras leer remitente y auto-sync desde almacén seguro (hidratación).
  final bool gmailPrefsLoaded;

  GmailSyncState copyWith({
    bool? isConfigured,
    bool? isConnected,
    String? connectedEmail,
    bool connectedEmailToNull = false,
    bool? isSyncing,
    String? lastResultMessage,
    bool lastResultMessageToNull = false,
    bool? autoSyncEnabled,
    String? senderFilter,
    bool senderFilterToNull = false,
    bool? gmailPrefsLoaded,
  }) {
    return GmailSyncState(
      isConfigured: isConfigured ?? this.isConfigured,
      isConnected: isConnected ?? this.isConnected,
      connectedEmail: connectedEmailToNull
          ? null
          : (connectedEmail ?? this.connectedEmail),
      isSyncing: isSyncing ?? this.isSyncing,
      lastResultMessage: lastResultMessageToNull
          ? null
          : (lastResultMessage ?? this.lastResultMessage),
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      senderFilter: senderFilterToNull
          ? null
          : (senderFilter ?? this.senderFilter),
      gmailPrefsLoaded: gmailPrefsLoaded ?? this.gmailPrefsLoaded,
    );
  }

  static const initial = GmailSyncState(
    isConfigured: true,
    isConnected: false,
    connectedEmail: null,
    isSyncing: false,
    lastResultMessage: null,
    autoSyncEnabled: false,
    senderFilter: null,
    gmailPrefsLoaded: false,
  );
}
