import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/secure_storage_provider.dart';
import '../../../core/providers/user_settings_providers.dart';
import '../../../core/providers/app_database_provider.dart';
import '../../../app.dart';
import '../../../data/local/app_database.dart';
import '../../../services/gmail_auth_service.dart';
import '../../../services/gmail_config_resolver.dart';
import '../../gmail/application/gmail_providers.dart';
import '../../saas/application/saas_providers.dart';
import '../../saas/presentation/saas_gmail_section.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/section_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(secureStorageServiceProvider);
    final userSettingsAsync = ref.watch(userSettingsStreamProvider);

    return AppScaffold(
      title: 'Configuración',
      selectedIndex: 3,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PdfPasswordSection(),
          const SizedBox(height: 20),
          _EditableSenderSection(userSettingsAsync: userSettingsAsync),
          const SizedBox(height: 20),
          const SaasGmailSection(),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Gmail local (opcional)',
            subtitle:
                'Solo si usas Google Sign-In en el teléfono. Si falla, usa el panel web '
                'https://rol-pagos-admin.vercel.app/settings o la sección SaaS de arriba.',
            child: Consumer(
              builder: (context, ref, _) {
                final gmailState = ref.watch(gmailSyncControllerProvider);
                final controller = ref.read(
                  gmailSyncControllerProvider.notifier,
                );
                final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

                final localAuthError = gmailState.lastResultMessage;
                final showLocalAuthHint = !gmailState.isConnected;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showLocalAuthHint) ...[
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localAuthError != null &&
                                        (localAuthError.toLowerCase().contains(
                                              'reauth',
                                            ) ||
                                            localAuthError.contains('[16]'))
                                    ? 'Account reauth failed / [16]'
                                    : 'Gmail local requiere OAuth alineado',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'google-services.json ya apunta a '
                                '“rol-pagos-saas-b7b04” con OAuth Android.\n\n'
                                'En OAuth (abajo) pega este Web Client ID:\n'
                                '${GmailAuthService.recommendedWebClientId}\n\n'
                                'Package: ${GmailAuthService.androidPackageName}\n'
                                'SHA-1 debug: ${GmailAuthService.debugSha1Fingerprint}\n\n'
                                'Alternativa: Gmail SaaS (arriba) o '
                                'https://rol-pagos-admin.vercel.app/gmail',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        gmailState.isConnected
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                      ),
                      title: Text(
                        gmailState.isConnected
                            ? 'Conectado: ${gmailState.connectedEmail ?? ''}'
                            : 'No conectado (local)',
                      ),
                      subtitle: Text(
                        gmailState.isConnected
                            ? 'Sincronización local activa.'
                            : 'El remitente se configura en la tarjeta de arriba. '
                                  'Si ves “Account reauth failed”, usa el panel web.',
                      ),
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('OAuth / conectar en el teléfono'),
                      children: [
                        _GmailOAuthClientIdSection(
                          hasServerClientIdConfigured: gmailState.isConfigured,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: !gmailState.isConfigured
                                    ? null
                                    : gmailState.isConnected
                                    ? () => controller.disconnect()
                                    : () => controller.connect(),
                                icon: Icon(
                                  gmailState.isConnected
                                      ? Icons.logout_outlined
                                      : Icons.login_outlined,
                                ),
                                label: Text(
                                  gmailState.isConnected
                                      ? 'Desconectar'
                                      : 'Conectar Gmail',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed:
                                    gmailState.isConnected &&
                                        !gmailState.isSyncing
                                    ? () => controller.syncNow()
                                    : null,
                                icon: gmailState.isSyncing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.sync),
                                label: Text(
                                  gmailState.isSyncing
                                      ? 'Sincronizando…'
                                      : 'Sincronizar',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: gmailState.autoSyncEnabled,
                      onChanged: gmailState.isConnected
                          ? (v) => controller.setAutoSyncEnabled(v)
                          : null,
                      title: const Text('Sincronización automática local'),
                      subtitle: const Text(
                        'Cada 6 horas en el teléfono (menos fiable que el backend).',
                      ),
                    ),
                    if (gmailState.lastResultMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        gmailState.lastResultMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    FutureBuilder<DateTime?>(
                      future: storage.getGmailLastBackgroundSyncAt(),
                      builder: (context, snapshot) {
                        final at = snapshot.data;
                        if (at == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Última ejecución (background): ${dateFmt.format(at)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo para OAuth Web Client ID guardado de forma segura (no requiere recompilar APK).
class _GmailOAuthClientIdSection extends ConsumerStatefulWidget {
  const _GmailOAuthClientIdSection({required this.hasServerClientIdConfigured});

  final bool hasServerClientIdConfigured;

  @override
  ConsumerState<_GmailOAuthClientIdSection> createState() =>
      _GmailOAuthClientIdSectionState();
}

class _GmailOAuthClientIdSectionState
    extends ConsumerState<_GmailOAuthClientIdSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromStorage());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFromStorage() async {
    final storage = ref.read(secureStorageServiceProvider);
    final v = await storage.getGmailServerClientId();
    if (!mounted) return;
    _controller.text = v ?? '';
    setState(() {});
  }

  Future<void> _save() async {
    final normalized = normalizeOAuthWebClientId(_controller.text);
    if (normalized == null || normalized.isEmpty) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Pega el OAuth Web Client ID')),
      );
      return;
    }
    if (!looksLikeOAuthWebClientId(normalized)) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'El ID no parece un Client ID Web (debe terminar en '
            '.apps.googleusercontent.com y NO empezar con https://).',
          ),
        ),
      );
      return;
    }
    _controller.text = normalized;
    final storage = ref.read(secureStorageServiceProvider);
    await storage.setGmailServerClientId(normalized);
    await ref
        .read(gmailSyncControllerProvider.notifier)
        .reloadGmailConfiguration();
    if (!mounted) return;
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Client ID guardado. Ya puedes pulsar “Conectar Gmail”.'),
      ),
    );
  }

  Future<void> _useRecommended() async {
    _controller.text = GmailAuthService.recommendedWebClientId;
    await _save();
  }

  Future<void> _clear() async {
    final storage = ref.read(secureStorageServiceProvider);
    await storage.deleteGmailServerClientId();
    _controller.clear();
    await ref
        .read(gmailSyncControllerProvider.notifier)
        .reloadGmailConfiguration();
    if (!mounted) return;
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Client ID eliminado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'OAuth Web Client ID',
            hintText: 'xxxxx-xxxxx.apps.googleusercontent.com',
            prefixIcon: Icon(Icons.vpn_key_outlined),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _useRecommended,
          icon: const Icon(Icons.auto_fix_high_outlined),
          label: const Text('Usar Client ID de rol-pagos-saas'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar Client ID'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(onPressed: _clear, child: const Text('Borrar')),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.hasServerClientIdConfigured
              ? 'Client ID cargado correctamente.'
              : 'Sin Client ID: pulsa “Usar Client ID de rol-pagos-saas” o pégalo y guarda.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Remitente editable (antes era solo lectura con texto "fase posterior").
class _EditableSenderSection extends ConsumerStatefulWidget {
  const _EditableSenderSection({required this.userSettingsAsync});

  final AsyncValue<UserSettingsTableData?> userSettingsAsync;

  @override
  ConsumerState<_EditableSenderSection> createState() =>
      _EditableSenderSectionState();
}

class _EditableSenderSectionState
    extends ConsumerState<_EditableSenderSection> {
  final _controller = TextEditingController();
  var _loadedKey = '';
  var _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Ingresa el correo del remitente')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      await db.userSettingsDao.updateGmailSenderFilter(value);
      await ref
          .read(gmailSyncControllerProvider.notifier)
          .setSenderFilter(value);
      // Si hay sesión SaaS, copia el remitente al servidor y reescanea.
      final saas = await ref.read(saasConfigProvider.future);
      if (saas.isReady) {
        try {
          final client = ref.read(rolPagosApiClientProvider);
          final result = await client.updateGmailFilters(
            organizationId: saas.organizationId!,
            senderFilter: value,
          );
          if (!mounted) return;
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(
                'Remitente guardado en app y servidor '
                '(+${result['documents_imported'] ?? 0} docs).',
              ),
            ),
          );
          return;
        } catch (_) {
          // No bloquear guardado local si el servidor falla.
        }
      }
      if (!mounted) return;
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Remitente guardado')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Remitente del rol',
      subtitle: 'Correo de quien envía el PDF (nómina), no tu Gmail personal.',
      child: widget.userSettingsAsync.when(
        data: (row) {
          final current = row?.gmailSenderFilter ?? '';
          if (_loadedKey != current) {
            _loadedKey = current;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_controller.text != current) {
                _controller.text = current;
              }
            });
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Correo del remitente',
                  hintText: 'ej. nomina@empresa.com',
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Guardando…' : 'Guardar remitente'),
              ),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('$e'),
      ),
    );
  }
}

/// Contraseña del PDF visible en pantalla (antes solo se abría por diálogo).
class _PdfPasswordSection extends ConsumerStatefulWidget {
  const _PdfPasswordSection();

  @override
  ConsumerState<_PdfPasswordSection> createState() =>
      _PdfPasswordSectionState();
}

class _PdfPasswordSectionState extends ConsumerState<_PdfPasswordSection> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _obscure = true;
  var _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(secureStorageServiceProvider)
          .savePdfPassword(_controller.text);
      ref.invalidate(pdfPasswordExistsProvider);
      _controller.clear();
      if (!mounted) return;
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Contraseña guardada de forma segura')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar contraseña'),
          content: const Text(
            'Se eliminará la contraseña guardada. Luego tendrás que ingresarla '
            'de nuevo para procesar PDFs protegidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(secureStorageServiceProvider).deletePdfPassword();
    ref.invalidate(pdfPasswordExistsProvider);
    if (!mounted) return;
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Contraseña eliminada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passwordExistsAsync = ref.watch(pdfPasswordExistsProvider);

    return SectionCard(
      title: 'Contraseña del PDF',
      subtitle:
          'Escríbela aquí. Se guarda en almacenamiento seguro del teléfono.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            passwordExistsAsync.when(
              data: (exists) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  exists ? Icons.lock_outline : Icons.lock_open_outlined,
                ),
                title: Text(exists ? 'Contraseña guardada' : 'Sin contraseña'),
                subtitle: Text(
                  exists
                      ? 'Ya puedes procesar roles protegidos'
                      : 'Ingresa la contraseña del PDF de nómina',
                ),
                trailing: exists
                    ? OutlinedButton(
                        onPressed: _delete,
                        child: const Text('Eliminar'),
                      )
                    : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controller,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Contraseña del PDF',
                hintText: 'La que pide el archivo al abrirlo',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.password_outlined),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Ingresa la contraseña';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Guardando…' : 'Guardar contraseña'),
            ),
          ],
        ),
      ),
    );
  }
}
