import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/app_database_provider.dart';
import '../application/saas_providers.dart';
import '../../../services/rol_pagos_api_client.dart';
import '../../../shared/widgets/section_card.dart';

/// Bloque de configuración para la API SaaS (Gmail offline en backend).
class SaasGmailSection extends ConsumerStatefulWidget {
  const SaasGmailSection({super.key});

  @override
  ConsumerState<SaasGmailSection> createState() => _SaasGmailSectionState();
}

class _SaasGmailSectionState extends ConsumerState<SaasGmailSection> {
  String? _statusLabel;
  String? _error;
  bool _loading = false;
  bool _autoReady = false;

  Future<void> _refreshStatus() async {
    final config = await ref.read(saasConfigProvider.future);
    if (!config.isReady) {
      setState(() {
        _statusLabel = 'Sin sesión SaaS. Pulsa “Sesión API” y pega token + organización.';
        _error = null;
        _autoReady = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(rolPagosApiClientProvider);
      final status = await client.gmailStatus(organizationId: config.organizationId!);
      final filters = await client.getGmailFilters(organizationId: config.organizationId!);
      final connected = status['connected'] == true ||
          (status['status']?.toString() == 'active');
      final sender = filters['sender_filter']?.toString();
      final watch = status['watch_expiration']?.toString();
      setState(() {
        _autoReady = connected && (sender != null && sender.isNotEmpty);
        _statusLabel = [
          '${status['status'] ?? 'desconocido'} · ${status['email_address'] ?? 'sin correo'}',
          if (sender != null && sender.isNotEmpty) 'Remitente servidor: $sender',
          if (sender == null || sender.isEmpty)
            'Falta remitente en servidor → pulsa “Activar automático”',
          if (watch != null && watch.isNotEmpty) 'Watch: $watch',
          if (_autoReady)
            'Automático listo: el servidor reconciliará periódicamente.',
        ].join('\n');
      });
    } on RolPagosApiException catch (e) {
      setState(() => _error = 'Error API (${e.statusCode}): ${e.body}');
    } catch (_) {
      setState(() => _error = 'No se pudo consultar el estado de Gmail');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _connect() async {
    final config = await ref.read(saasConfigProvider.future);
    if (!config.isReady) {
      setState(() => _error = 'Configura URL, token y organización en “Sesión API”');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(rolPagosApiClientProvider);
      final data = await client.gmailAuthorize(organizationId: config.organizationId!);
      final url = data['authorization_url'] as String?;
      if (url == null) {
        setState(() => _error = 'La API no devolvió authorization_url');
        return;
      }
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        setState(() => _error = 'No se pudo abrir el navegador para OAuth');
      }
    } on RolPagosApiException catch (e) {
      setState(() => _error = 'Error al iniciar OAuth (${e.statusCode})');
    } catch (_) {
      setState(() => _error = 'Error al conectar Gmail vía backend');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sync({bool full = false}) async {
    final config = await ref.read(saasConfigProvider.future);
    if (!config.isReady) return;
    setState(() => _loading = true);
    try {
      final client = ref.read(rolPagosApiClientProvider);
      final result = await client.gmailSync(
        organizationId: config.organizationId!,
        full: full,
      );
      setState(() => _statusLabel = result['message']?.toString() ?? 'Sincronizado');
    } on RolPagosApiException catch (e) {
      setState(() => _error = 'Error al sincronizar (${e.statusCode})');
    } catch (_) {
      setState(() => _error = 'Error al sincronizar');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Copia el remitente local al servidor y fuerza sync completa.
  Future<void> _activateAutomatic() async {
    final config = await ref.read(saasConfigProvider.future);
    if (!config.isReady) {
      setState(() => _error = 'Primero configura “Sesión API” (token + organización).');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = ref.read(appDatabaseProvider);
      final settings = await db.userSettingsDao.getSettings();
      final sender = (settings?.gmailSenderFilter ?? '').trim();
      if (sender.isEmpty) {
        setState(() {
          _error =
              'Guarda primero el “Correo del remitente” (ej. umanos.Nomina@vicunha.com.ec).';
        });
        return;
      }
      final client = ref.read(rolPagosApiClientProvider);
      final filters = await client.updateGmailFilters(
        organizationId: config.organizationId!,
        senderFilter: sender,
      );
      final imported = filters['documents_imported'];
      setState(() {
        _statusLabel =
            'Automático activado.\nRemitente: $sender\n'
            'Importados en este escaneo: ${imported ?? 0}\n'
            'El servidor seguirá buscando correos nuevos en segundo plano.';
        _autoReady = true;
      });
    } on RolPagosApiException catch (e) {
      final body = e.body.toLowerCase();
      if (e.statusCode == 404 || body.contains('not_connected')) {
        setState(() => _error = 'Conecta Gmail SaaS primero (botón Conectar Gmail).');
      } else {
        setState(() => _error = 'No se pudo activar automático (${e.statusCode})');
      }
    } catch (_) {
      setState(() => _error = 'No se pudo activar el modo automático');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editConfig() async {
    final baseCtrl = TextEditingController();
    final tokenCtrl = TextEditingController();
    final orgCtrl = TextEditingController();
    final config = await ref.read(saasConfigProvider.future);
    baseCtrl.text = config.baseUrl;
    tokenCtrl.text = config.accessToken ?? '';
    orgCtrl.text = config.organizationId ?? '';

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sesión SaaS'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Obtén token y Organization ID en '
                'https://rol-pagos-admin.vercel.app/login',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baseCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL API',
                  hintText: 'https://rolpagos-api.onrender.com',
                ),
              ),
              TextField(
                controller: tokenCtrl,
                decoration: const InputDecoration(labelText: 'Access token'),
                obscureText: true,
              ),
              TextField(
                controller: orgCtrl,
                decoration: const InputDecoration(labelText: 'Organization ID'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (saved == true) {
      await SaasConfigRepository().save(
        baseUrl: baseCtrl.text.trim(),
        accessToken: tokenCtrl.text.trim(),
        organizationId: orgCtrl.text.trim(),
      );
      ref.invalidate(saasConfigProvider);
      await _refreshStatus();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStatus());
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'SaaS · Gmail automático (recomendado)',
      subtitle:
          'Descarga en el servidor sin depender del teléfono. '
          '1) Sesión API  2) Conectar Gmail  3) Activar automático.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _autoReady ? Icons.verified_outlined : Icons.cloud_sync_outlined,
              color: _autoReady ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(_autoReady ? 'Automático activo' : 'Estado en servidor'),
            subtitle: Text(_error ?? _statusLabel ?? 'Sin datos'),
          ),
          if (_loading) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(onPressed: _editConfig, child: const Text('Sesión API')),
              FilledButton(
                onPressed: _loading ? null : _connect,
                child: const Text('Conectar Gmail'),
              ),
              FilledButton.tonal(
                onPressed: _loading ? null : _activateAutomatic,
                child: const Text('Activar automático'),
              ),
              OutlinedButton(
                onPressed: _loading ? null : () => _sync(full: true),
                child: const Text('Sincronizar ahora'),
              ),
              OutlinedButton(
                onPressed: _loading ? null : _refreshStatus,
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
