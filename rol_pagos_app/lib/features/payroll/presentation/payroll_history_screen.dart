import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/secure_storage_provider.dart';
import '../../hours/application/manual_hours_controller.dart';
import '../../../core/utils/year_month.dart';
import '../../hours/domain/hour_balance.dart';
import '../../hours/domain/hour_payment.dart';
import '../../../app.dart';
import '../domain/payroll_document.dart';
import '../application/payroll_providers.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/section_card.dart';

class PayrollHistoryScreen extends ConsumerWidget {
  const PayrollHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsForCurrentMonthProvider);
    final payrollsAsync = ref.watch(payrollDocumentsProvider);

    return AppScaffold(
      title: 'Historial',
      selectedIndex: 2,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Roles de pago',
            subtitle:
                'Aquí aparecerán los PDFs importados, su estado de procesamiento y las horas detectadas.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _importPdf(context, ref),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Importar PDF'),
                  ),
                ),
                const SizedBox(height: 14),
                payrollsAsync.when(
                  data: (payrolls) => payrolls.isEmpty
                      ? const _EmptyState(
                          icon: Icons.picture_as_pdf_outlined,
                          title: 'Sin roles importados',
                          description:
                              'Importa un PDF local para registrarlo en el historial.',
                        )
                      : _PayrollList(
                          payrolls: payrolls,
                          onProcess: (payroll) =>
                              _processPayroll(context, ref, payroll),
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('$error'),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          SectionCard(
            title: 'Pagos registrados',
            subtitle: 'Pagos manuales guardados localmente en el dispositivo.',
            child: paymentsAsync.when(
              data: (payments) => payments.isEmpty
                  ? const _EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Sin pagos registrados',
                      description:
                          'Cuando registres pagos, verás fecha, horas, porcentaje y equivalente.',
                    )
                  : _PaymentsList(payments: payments),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('$error'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importPdf(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final path = result.files.single.path;
    final fileName = result.files.single.name;
    if (path == null) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('No se pudo leer el archivo seleccionado'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final ym = await _pickYearMonth(
      context,
      initialYear: now.year,
      initialMonth: now.month,
    );
    if (ym == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final repo = ref.read(payrollRepositoryProvider);
    final importResult = await repo.importLocalPdf(
      sourcePath: path,
      originalFileName: fileName,
      year: ym.year,
      month: ym.month,
    );

    if (!context.mounted) {
      return;
    }

    final message = importResult.success
        ? 'Rol importado correctamente'
        : (importResult.message ?? 'No se pudo importar el rol');

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<_YearMonth?> _pickYearMonth(
    BuildContext context, {
    required int initialYear,
    required int initialMonth,
  }) async {
    int year = initialYear;
    int month = initialMonth;

    return showDialog<_YearMonth>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Mes/Año del rol'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: month,
                decoration: const InputDecoration(labelText: 'Mes'),
                items: [
                  for (var m = 1; m <= 12; m++)
                    DropdownMenuItem(value: m, child: Text(m.toString())),
                ],
                onChanged: (v) => month = v ?? month,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: year,
                decoration: const InputDecoration(labelText: 'Año'),
                items: [
                  for (var y = initialYear - 2; y <= initialYear + 1; y++)
                    DropdownMenuItem(value: y, child: Text(y.toString())),
                ],
                onChanged: (v) => year = v ?? year,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_YearMonth(year, month)),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPayroll(
    BuildContext context,
    WidgetRef ref,
    PayrollDocument payroll,
  ) async {
    final storage = ref.read(secureStorageServiceProvider);
    final savedPassword = await storage.getPdfPassword();
    if (!context.mounted) return;

    String? passwordToUse = savedPassword;
    if ((passwordToUse ?? '').trim().isEmpty) {
      passwordToUse = await _askPdfPassword(context);
    }
    if (passwordToUse == null) return;
    if (!context.mounted) return;

    final repo = ref.read(payrollRepositoryProvider);
    var result = await repo.processPayroll(
      payroll: payroll,
      password: passwordToUse,
    );

    // Si falló por contraseña y teníamos una guardada, damos opción de reintento manual.
    if (!result.success &&
        savedPassword != null &&
        savedPassword.isNotEmpty &&
        (result.message ?? '').toLowerCase().contains('contraseña')) {
      if (!context.mounted) return;
      final retryPassword = await _askPdfPassword(context);
      if (retryPassword != null && context.mounted) {
        result = await repo.processPayroll(
          payroll: payroll,
          password: retryPassword,
        );
      }
    }

    if (!context.mounted) {
      return;
    }

    final msg = result.success
        ? 'PDF procesado. Revisa los datos detectados.'
        : (result.message ?? 'No se pudo procesar el PDF');
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<String?> _askPdfPassword(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => const _PayrollPdfPasswordDialog(),
    );
  }
}

class _PayrollPdfPasswordDialog extends StatefulWidget {
  const _PayrollPdfPasswordDialog();

  @override
  State<_PayrollPdfPasswordDialog> createState() =>
      _PayrollPdfPasswordDialogState();
}

class _PayrollPdfPasswordDialogState extends State<_PayrollPdfPasswordDialog> {
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
      title: const Text('Contraseña del PDF'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Contraseña',
            hintText: 'Se usa solo para procesar este PDF',
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
          child: const Text('Procesar'),
        ),
      ],
    );
  }
}

class _PaymentsList extends StatelessWidget {
  _PaymentsList({required this.payments});

  final List<HourPayment> payments;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final payment in payments)
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(
                '${payment.hours.toStringAsFixed(1)} h al ${payment.percentage.toStringAsFixed(0)}%',
              ),
              subtitle: Text(
                [
                  _dateFormat.format(payment.date),
                  'Equivalente: ${payment.equivalentHours.toStringAsFixed(1)} h',
                  if (payment.observation != null) payment.observation!,
                ].join(' · '),
              ),
              trailing: PopupMenuButton<_PaymentAction>(
                onSelected: (action) async {
                  if (action == _PaymentAction.edit) {
                    await _editPayment(context, payment);
                  } else if (action == _PaymentAction.delete) {
                    await _confirmDelete(context, payment);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _PaymentAction.edit,
                    child: Text('Editar'),
                  ),
                  PopupMenuItem(
                    value: _PaymentAction.delete,
                    child: Text('Eliminar'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, HourPayment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar pago'),
        content: Text(
          '¿Eliminar el pago de ${payment.hours.toStringAsFixed(1)} h '
          '(${_dateFormat.format(payment.date)})?',
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
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ref = ProviderScope.containerOf(context);
    await ref.read(manualHoursControllerProvider).deletePayment(id: payment.id);
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Pago eliminado')),
    );
  }

  Future<void> _editPayment(BuildContext context, HourPayment payment) async {
    final result = await showDialog<_EditPaymentResult>(
      context: context,
      builder: (dialogContext) => _EditPaymentDialog(payment: payment),
    );

    if (result == null || !context.mounted) return;

    final ref = ProviderScope.containerOf(context);
    await ref.read(manualHoursControllerProvider).updatePayment(
          id: payment.id,
          date: result.date,
          hours: result.hours,
          percentage: result.percentage,
          observation: result.observation,
        );

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Pago actualizado')),
    );
  }
}

enum _PaymentAction { edit, delete }

class _EditPaymentResult {
  const _EditPaymentResult({
    required this.date,
    required this.hours,
    required this.percentage,
    required this.observation,
  });

  final DateTime date;
  final double hours;
  final double percentage;
  final String? observation;
}

class _EditPaymentDialog extends StatefulWidget {
  const _EditPaymentDialog({required this.payment});

  final HourPayment payment;

  @override
  State<_EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<_EditPaymentDialog> {
  late DateTime _date;
  late final TextEditingController _hoursController;
  late final TextEditingController _obsController;
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  double _percentage = 100;

  @override
  void initState() {
    super.initState();
    _date = widget.payment.date;
    _percentage = widget.payment.percentage;
    _hoursController = TextEditingController(
      text: widget.payment.hours.toStringAsFixed(1),
    );
    _obsController = TextEditingController(text: widget.payment.observation);
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  double? _parseNumber(String? value) {
    if (value == null) return null;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String? _validatePositiveNumber(String? value) {
    final parsed = _parseNumber(value);
    if (parsed == null || parsed <= 0) {
      return 'Ingresa un valor mayor a cero';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2),
    );

    if (pickedDate != null) {
      setState(() => _date = pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar pago'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: ValueKey(_date),
              readOnly: true,
              initialValue: _dateFormat.format(_date),
              decoration: const InputDecoration(
                labelText: 'Fecha',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hoursController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cantidad de horas',
                prefixIcon: Icon(Icons.access_time),
              ),
              validator: _validatePositiveNumber,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<double>(
              initialValue: _percentage,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 100, child: Text('100% (x1.00)')),
                DropdownMenuItem(value: 50, child: Text('50% (x0.50)')),
                DropdownMenuItem(value: 30, child: Text('30% (x0.30)')),
                DropdownMenuItem(value: 120, child: Text('Recargo 20% (x1.20)')),
                DropdownMenuItem(value: 125, child: Text('Recargo 25% (x1.25)')),
                DropdownMenuItem(
                  value: 130,
                  child: Text('Equivalencia 1→1.30 (x1.30)'),
                ),
                DropdownMenuItem(
                  value: 200,
                  child: Text('Descanso: 2 días compensados (x2.00)'),
                ),
                DropdownMenuItem(value: 240, child: Text('2 días + 20% (x2.40)')),
                DropdownMenuItem(value: 250, child: Text('2 días + 25% (x2.50)')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _percentage = value);
              },
              decoration: const InputDecoration(
                labelText: 'Porcentaje de pago',
                prefixIcon: Icon(Icons.percent),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _obsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observación',
                alignLabelWithHint: true,
                hintText: 'Detalle opcional',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;

            final hours = _parseNumber(_hoursController.text)!;
            Navigator.of(context).pop(
              _EditPaymentResult(
                date: _date,
                hours: hours,
                percentage: _percentage,
                observation: _obsController.text,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(icon, size: 42, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollList extends StatelessWidget {
  _PayrollList({required this.payrolls, required this.onProcess});

  final List<PayrollDocument> payrolls;
  final void Function(PayrollDocument payroll) onProcess;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final p in payrolls)
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 10),
            child: Consumer(
              builder: (context, ref, _) {
                final ym = YearMonth(year: p.year, month: p.month);
                final balanceAsync = ref.watch(balanceForMonthProvider(ym));

                final hasDetected = p.detectedDebtHours != null ||
                    p.detectedPaidHours != null ||
                    p.detectedPendingHours != null;

                return ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(
                '${p.month.toString().padLeft(2, '0')}/${p.year} · ${p.fileName}',
              ),
              subtitle: Text(
                [
                  'Estado: ${_statusLabel(p.status)}',
                  'Importado: ${_dateFormat.format(p.importedAt)}',
                  if (p.processedAt != null)
                    'Procesado: ${_dateFormat.format(p.processedAt!)}',
                  if (p.fileHash != null)
                    'Hash: ${p.fileHash!.substring(0, 10)}…',
                  if (p.detectedDebtHours != null)
                    'Deuda detectada: ${p.detectedDebtHours!.toStringAsFixed(1)}h',
                ].join(' · '),
              ),
              trailing: hasDetected
                  ? balanceAsync.when(
                      data: (balance) {
                        final issues = _comparePayrollVsBalance(p, balance);
                        if (issues.isEmpty) {
                          return const Icon(Icons.verified_outlined);
                        }
                        return Tooltip(
                          message: issues.join('\n'),
                          child: const Icon(
                            Icons.warning_amber_outlined,
                            color: Colors.orange,
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (error, stack) => const Icon(Icons.help_outline),
                    )
                  : (p.status == PayrollDocumentStatus.processed
                      ? const Icon(Icons.check_circle_outline)
                      : null),
              onTap: () async {
                if (!hasDetected) return;
                final balance = await balanceAsync.maybeWhen(
                  data: (v) async => v,
                  orElse: () async => null,
                );
                if (!context.mounted || balance == null) return;
                final issues = _comparePayrollVsBalance(p, balance);
                await showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Conciliación del rol'),
                    content: Text(
                      issues.isEmpty
                          ? 'Sin discrepancias detectadas.'
                          : issues.join('\n'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
            );
              },
            ),
          ),
      ],
    );
  }

  String _statusLabel(PayrollDocumentStatus status) {
    return switch (status) {
      PayrollDocumentStatus.imported => 'Importado',
      PayrollDocumentStatus.pendingPassword => 'Pendiente contraseña',
      PayrollDocumentStatus.processed => 'Procesado',
      PayrollDocumentStatus.duplicated => 'Duplicado',
      PayrollDocumentStatus.failed => 'Fallido',
    };
  }

  List<String> _comparePayrollVsBalance(
    PayrollDocument payroll,
    HourBalanceResult balance,
  ) {
    const tolerance = 0.1;
    final issues = <String>[];

    void check(String label, double? detected, double actual) {
      if (detected == null) return;
      final detectedAbs = detected.abs();
      final diff = (detectedAbs - actual).abs();
      if (diff > tolerance) {
        issues.add(
          '$label: PDF ${detected.toStringAsFixed(1)}h vs App ${actual.toStringAsFixed(1)}h (Δ ${diff.toStringAsFixed(1)}h)',
        );
      }
    }

    // En el rol puede venir negativo (deuda). Comparamos por magnitud.
    check('Saldo anterior (deuda)', payroll.detectedDebtHours, balance.totalDebtHours);
    // En app: paid es equivalente. En PDF asumimos que "pagadas" es equivalente; si no, se ajusta luego.
    check('Pagadas (eq.)', payroll.detectedPaidHours, balance.totalPaidHours);

    // "Saldo actual" puede venir negativo (pendiente) o positivo (a favor).
    final detectedCurrent = payroll.detectedPendingHours;
    if (detectedCurrent != null) {
      if (detectedCurrent < 0) {
        check('Saldo actual (pendiente)', detectedCurrent, balance.pendingHours);
      } else {
        check('Saldo actual (a favor)', detectedCurrent, balance.overtimeHours);
      }
    }

    return issues;
  }
}

class _YearMonth {
  const _YearMonth(this.year, this.month);

  final int year;
  final int month;
}
