import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/secure_storage_provider.dart';
import '../../../core/providers/user_settings_providers.dart';
import '../../../app.dart';
import '../../../background/background_tasks.dart';
import '../../../services/gmail_config_resolver.dart';
import '../../gmail/application/gmail_providers.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/section_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordExistsAsync = ref.watch(pdfPasswordExistsProvider);
    final storage = ref.watch(secureStorageServiceProvider);
    final userSettingsAsync = ref.watch(userSettingsStreamProvider);

    return AppScaffold(
      title: 'Configuración',
      selectedIndex: 3,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Seguridad del PDF',
            subtitle:
                'La contraseña se guarda usando almacenamiento seguro. No se escribe en el código fuente.',
            child: Column(
              children: [
                passwordExistsAsync.when(
                  data: (exists) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Contraseña del PDF'),
                    subtitle: Text(
                      exists
                          ? 'Guardada en almacenamiento seguro'
                          : 'No configurada',
                    ),
                    trailing: exists
                        ? OutlinedButton(
                            onPressed: () => _deletePassword(context, ref),
                            child: const Text('Eliminar'),
                          )
                        : null,
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('$error'),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _setPassword(context, ref),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Guardar / actualizar'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Gmail',
            subtitle:
                'Conecta tu cuenta para buscar y descargar adjuntos PDF automáticamente.',
            child: Consumer(
              builder: (context, ref, _) {
                final gmailState = ref.watch(gmailSyncControllerProvider);
                final controller = ref.read(
                  gmailSyncControllerProvider.notifier,
                );
                final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                            : 'No conectado',
                      ),
                      subtitle: Text(
                        gmailState.isConnected
                            ? 'Puedes sincronizar adjuntos PDF del remitente configurado.'
                            : gmailState.isConfigured
                                ? 'Toca “Conectar Gmail” para autorizar el acceso (solo lectura).'
                                : 'Google Sign-In no está configurado aún para Gmail.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'En Google Cloud Console crea un cliente OAuth de tipo “Web application” y pega aquí su ID. '
                      'Añade también el tipo Android con package com.rolhoras.rol_pagos_app y el SHA-1 de firma (debug/release). '
                      'Opcional: compilar con dart-define GMAIL_SERVER_CLIENT_ID.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    _GmailOAuthClientIdSection(
                      hasServerClientIdConfigured: gmailState.isConfigured,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: ValueKey(gmailState.gmailPrefsLoaded),
                      initialValue: gmailState.senderFilter ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Correo del remitente (quien envía el rol)',
                        helperText:
                            'Ej. RecursosHumanos.Nomina@vicunha.com.ec',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      onChanged: (v) => controller.setSenderFilter(v),
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
                                gmailState.isConnected && !gmailState.isSyncing
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
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: gmailState.autoSyncEnabled,
                      onChanged: gmailState.isConnected
                          ? (v) => controller.setAutoSyncEnabled(v)
                          : null,
                      title: const Text(
                        'Sincronización automática (foreground + background)',
                      ),
                      subtitle: const Text(
                        'Ejecuta cada 6 horas mientras la app está abierta. '
                        'En Android también programa ejecución en segundo plano.',
                      ),
                    ),
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
                    FutureBuilder<String?>(
                      future: storage.getGmailLastBackgroundSyncResult(),
                      builder: (context, snapshot) {
                        final msg = snapshot.data;
                        if (msg == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            msg,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                    if (gmailState.lastResultMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        gmailState.lastResultMessage!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: gmailState.isConnected
                            ? () async {
                                // Registrar/cancelar según toggle actual.
                                final enabled =
                                    await storage.getGmailAutoSyncEnabled();
                                if (enabled) {
                                  await BackgroundTasks.registerGmailSync();
                                  rootScaffoldMessengerKey.currentState
                                      ?.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Sync en segundo plano programado (Android)',
                                      ),
                                    ),
                                  );
                                } else {
                                  await BackgroundTasks.cancelGmailSync();
                                  rootScaffoldMessengerKey.currentState
                                      ?.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Sync en segundo plano desactivado',
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.schedule),
                        label: const Text('Aplicar programación en segundo plano'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Remitente por defecto (base local)',
            subtitle:
                'Valor sembrado en la base de datos. El remitente activo para Gmail lo configuras arriba.',
            child: userSettingsAsync.when(
              data: (row) {
                if (row == null) {
                  return const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.mail_outline),
                    title: Text('Sin registro de configuración'),
                    subtitle: Text(
                      'Reinicia la app; debería crearse al abrir la base de datos.',
                    ),
                  );
                }
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mail_outline),
                  title: Text(row.gmailSenderFilter),
                  subtitle: const Text(
                    'Edición de este campo en BD puede añadirse en una fase posterior.',
                  ),
                );
              },
              loading: () => const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.mail_outline),
                title: Text('Cargando…'),
              ),
              error: (e, _) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.error_outline),
                title: Text('Error: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setPassword(BuildContext context, WidgetRef ref) async {
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _SettingsPdfPasswordDialog(),
    );

    if (password == null) return;
    if (!context.mounted) return;

    await ref.read(secureStorageServiceProvider).savePdfPassword(password);
    ref.invalidate(pdfPasswordExistsProvider);

    if (!context.mounted) return;
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Contraseña guardada de forma segura')),
    );
  }

  Future<void> _deletePassword(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar contraseña'),
          content: const Text(
            'Se eliminará la contraseña guardada. Luego tendrás que ingresarla manualmente para procesar PDFs.',
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
    if (!context.mounted) return;

    await ref.read(secureStorageServiceProvider).deletePdfPassword();
    ref.invalidate(pdfPasswordExistsProvider);

    if (!context.mounted) return;
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Contraseña eliminada')),
    );
  }
}

/// Campo para OAuth Web Client ID guardado de forma segura (no requiere recompilar APK).
class _GmailOAuthClientIdSection extends ConsumerStatefulWidget {
  const _GmailOAuthClientIdSection({
    required this.hasServerClientIdConfigured,
  });

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
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Pega el OAuth Web Client ID')),
      );
      return;
    }
    if (!looksLikeOAuthWebClientId(raw)) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'El ID no parece un Client ID Web (debe terminar en .apps.googleusercontent.com). '
            'Si es correcto igualmente, vuelve a guardar tras revisar.',
          ),
        ),
      );
    }
    final storage = ref.read(secureStorageServiceProvider);
    await storage.setGmailServerClientId(raw);
    await ref.read(gmailSyncControllerProvider.notifier).reloadGmailConfiguration();
    if (!mounted) return;
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Client ID guardado. Ya puedes usar Conectar Gmail')),
    );
  }

  Future<void> _clear() async {
    final storage = ref.read(secureStorageServiceProvider);
    await storage.deleteGmailServerClientId();
    _controller.clear();
    await ref.read(gmailSyncControllerProvider.notifier).reloadGmailConfiguration();
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
            OutlinedButton(
              onPressed: _clear,
              child: const Text('Borrar'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.hasServerClientIdConfigured
              ? 'Client ID cargado correctamente.'
              : 'Sin Client ID: “Conectar Gmail” permanecerá deshabilitado hasta guardar.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _SettingsPdfPasswordDialog extends StatefulWidget {
  const _SettingsPdfPasswordDialog();

  @override
  State<_SettingsPdfPasswordDialog> createState() =>
      _SettingsPdfPasswordDialogState();
}

class _SettingsPdfPasswordDialogState
    extends State<_SettingsPdfPasswordDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Guardar contraseña del PDF'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Contraseña',
            hintText: 'No se mostrará en pantalla',
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Ingresa la contraseña';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(_controller.text);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
