import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _refreshStatus() async {
    final config = await ref.read(saasConfigProvider.future);
    if (!config.isReady) {
      setState(() {
        _statusLabel = 'Sin sesión SaaS configurada';
        _error = null;
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
      setState(() {
        _statusLabel =
            '${status['status']} · ${status['email_address'] ?? 'sin correo'}';
      });
    } on RolPagosApiException catch (e) {
      setState(() => _error = 'Error API (${e.statusCode})');
    } catch (e) {
      setState(() => _error = 'No se pudo consultar el estado de Gmail');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _connect() async {
    final config = await ref.read(saasConfigProvider.future);
    if (!config.isReady) {
      setState(() => _error = 'Configura URL, token y organización en almacenamiento seguro');
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

  Future<void> _sync() async {
    final config = await ref.read(saasConfigProvider.future);
    if (!config.isReady) return;
    setState(() => _loading = true);
    try {
      final client = ref.read(rolPagosApiClientProvider);
      final result = await client.gmailSync(organizationId: config.organizationId!);
      setState(() => _statusLabel = result['message']?.toString() ?? 'Sincronizado');
    } catch (_) {
      setState(() => _error = 'Error al sincronizar');
    } finally {
      setState(() => _loading = false);
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
              TextField(
                controller: baseCtrl,
                decoration: const InputDecoration(labelText: 'URL API'),
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
          'Usa esta opción. OAuth offline en la API; la descarga sigue con la app cerrada. '
          'El Gmail local del teléfono es opcional y ya está alineado con rol-pagos-saas-b7b04.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('Estado en servidor'),
            subtitle: Text(_error ?? _statusLabel ?? 'Sin datos'),
          ),
          if (_loading) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(onPressed: _editConfig, child: const Text('Sesión API')),
              FilledButton(onPressed: _loading ? null : _connect, child: const Text('Conectar Gmail')),
              OutlinedButton(onPressed: _loading ? null : _sync, child: const Text('Sincronizar ahora')),
              OutlinedButton(onPressed: _loading ? null : _refreshStatus, child: const Text('Actualizar')),
            ],
          ),
        ],
      ),
    );
  }
}
