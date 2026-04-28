import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_routes.dart';
import '../application/dashboard_summary_provider.dart';
import '../../hours/application/manual_hours_controller.dart';
import '../../hours/domain/hour_balance.dart';
import '../../hours/domain/hour_payment.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/section_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return AppScaffold(
      title: 'Dashboard',
      selectedIndex: 0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.registerHours),
        icon: const Icon(Icons.add),
        label: const Text('Registrar pago'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Control mensual de horas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Dashboard profesional (Fase 3): tarjetas, progreso, gráfico y resumen mensual.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          summaryAsync.when(
            data: (summary) {
              final balance = summary.balance;
              final progress = balance.totalDebtHours <= 0
                  ? 0.0
                  : math.min(
                      balance.totalPaidHours / balance.totalDebtHours,
                      1.0,
                    );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MetricsGrid(balance: balance),
                  const SizedBox(height: 20),
                  _ProgressCard(balance: balance, progress: progress),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Distribución de pagos (equivalente)',
                    subtitle: summary.paymentsCount == 0
                        ? 'Registra pagos para ver el gráfico.'
                        : 'Horas equivalentes acumuladas por porcentaje.',
                    child: _PaymentsChart(
                      equivalentByPercentage: summary.equivalentByPercentage,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Resumen del mes',
                    subtitle: 'Último movimiento y totales calculados.',
                    child: _MonthlySummary(
                      balance: balance,
                      paymentsCount: summary.paymentsCount,
                      lastPayment: summary.lastPayment,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Deuda manual del mes',
                    subtitle:
                        'Ingresa las horas adeudadas detectadas o conocidas para calcular el saldo.',
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Text(
                          '${_formatHours(balance.totalDebtHours)} horas configuradas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showDebtDialog(
                            context,
                            ref,
                            currentDebt: balance.totalDebtHours,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Actualizar deuda'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const _LoadingCards(),
            error: (error, stack) => SectionCard(
              title: 'Error cargando datos',
              subtitle: 'No se pudo leer la base local.',
              child: Text('$error'),
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Acciones rápidas',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useColumn = constraints.maxWidth < 420;

                final actions = [
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.registerHours),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Registrar pago de horas'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.payrollHistory),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Ver historial'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.settings),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Configurar contraseña PDF'),
                  ),
                ];

                if (useColumn) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        SizedBox(width: double.infinity, child: actions[i]),
                        if (i != actions.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                return Wrap(spacing: 12, runSpacing: 12, children: actions);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(double value) => value.toStringAsFixed(1);

  Future<void> _showDebtDialog(
    BuildContext context,
    WidgetRef ref, {
    required double currentDebt,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _UpdateDebtDialog(
          currentDebt: currentDebt,
          onSave: (debt) async {
            await ref.read(manualHoursControllerProvider).updateDebtHours(debt);
          },
        );
      },
    );
  }
}

/// El [TextEditingController] vive en el [State] y se libera al cerrar el diálogo.
/// No disponer el control justo al volver de [showDialog]: en Android el IME
/// aún puede tocarlo y provoca "used after dispose" y fallos de framework.
class _UpdateDebtDialog extends StatefulWidget {
  const _UpdateDebtDialog({required this.currentDebt, required this.onSave});

  final double currentDebt;
  final Future<void> Function(double debt) onSave;

  @override
  State<_UpdateDebtDialog> createState() => _UpdateDebtDialogState();
}

class _UpdateDebtDialogState extends State<_UpdateDebtDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentDebt == 0 ? '' : widget.currentDebt.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Actualizar horas adeudadas'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Horas adeudadas',
            hintText: 'Ej. 10.5',
          ),
          validator: (value) {
            final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
            if (parsed == null || parsed < 0) {
              return 'Ingresa un número igual o mayor a cero';
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
          onPressed: () async {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            final debt = double.parse(_controller.text.replaceAll(',', '.'));
            await widget.onSave(debt);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final HourBalanceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      HourBalanceStatus.pending => Colors.orange,
      HourBalanceStatus.paid => Colors.green,
      HourBalanceStatus.overtime => Colors.blue,
    };

    return Chip(
      avatar: Icon(Icons.circle, size: 12, color: color),
      label: Text(status.label),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}

class _LoadingCards extends StatelessWidget {
  const _LoadingCards();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width >= 900 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: const [
        _MetricCardPro(
          label: 'Horas adeudadas',
          value: '...',
          icon: Icons.schedule,
        ),
        _MetricCardPro(
          label: 'Pagadas',
          value: '...',
          icon: Icons.payments_outlined,
        ),
        _MetricCardPro(
          label: 'Pendientes',
          value: '...',
          icon: Icons.warning_amber_outlined,
        ),
        _MetricCardPro(label: 'A favor', value: '...', icon: Icons.trending_up),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.balance});

  final HourBalanceResult balance;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width >= 900 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _MetricCardPro(
          label: 'Horas adeudadas',
          value: balance.totalDebtHours.toStringAsFixed(1),
          icon: Icons.schedule,
        ),
        _MetricCardPro(
          label: 'Pagadas (eq.)',
          value: balance.totalPaidHours.toStringAsFixed(1),
          icon: Icons.payments_outlined,
        ),
        _MetricCardPro(
          label: 'Pendientes',
          value: balance.pendingHours.toStringAsFixed(1),
          icon: Icons.warning_amber_outlined,
        ),
        _MetricCardPro(
          label: 'A favor',
          value: balance.overtimeHours.toStringAsFixed(1),
          icon: Icons.trending_up,
        ),
      ],
    );
  }
}

class _MetricCardPro extends StatelessWidget {
  const _MetricCardPro({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 125;
          // En celdas muy bajas (rotación/pantallas angostas), compactamos aún más
          // para evitar RenderFlex overflow por pocos px.
          final ultraCompact = constraints.maxHeight < 116;

          final padding = ultraCompact ? 12.0 : (compact ? 14.0 : 18.0);
          final iconPadding = ultraCompact ? 6.0 : (compact ? 8.0 : 10.0);
          final gapAfterIcon = ultraCompact ? 6.0 : (compact ? 10.0 : 14.0);

          final valueStyle = compact
              ? theme.textTheme.titleLarge
              : theme.textTheme.headlineMedium;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(iconPadding),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        color: cs.primary,
                        size: ultraCompact ? 18 : null,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                SizedBox(height: gapAfterIcon),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: valueStyle),
                ),
                SizedBox(height: ultraCompact ? 0 : 2),
                Text(
                  label,
                  maxLines: ultraCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: ultraCompact ? 1.0 : (compact ? 1.1 : null),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.balance, required this.progress});

  final HourBalanceResult balance;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Progreso mensual',
      subtitle: 'Estado actual: ${balance.status.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusChip(status: balance.status),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()}% pagado (equivalente)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentsChart extends StatelessWidget {
  const _PaymentsChart({required this.equivalentByPercentage});

  final Map<double, double> equivalentByPercentage;

  @override
  Widget build(BuildContext context) {
    if (equivalentByPercentage.isEmpty) {
      return const _EmptyInline(
        icon: Icons.bar_chart_outlined,
        text: 'Sin datos aún',
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final entries = equivalentByPercentage.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final bars = <BarChartGroupData>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: e.value,
              width: 18,
              borderRadius: BorderRadius.circular(6),
              color: cs.primary,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 170,
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${entries[index].key.toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: bars,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final e in entries)
              Chip(
                label: Text(
                  '${e.key.toStringAsFixed(0)}%: ${e.value.toStringAsFixed(1)} h',
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  _MonthlySummary({
    required this.balance,
    required this.paymentsCount,
    required this.lastPayment,
  });

  final HourBalanceResult balance;
  final int paymentsCount;
  final HourPayment? lastPayment;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final last = lastPayment;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text('$paymentsCount pago(s) registrado(s)'),
          subtitle: Text(
            last == null
                ? 'No hay pagos todavía'
                : 'Último: ${_dateFormat.format(last.date)} · '
                      '${last.hours.toStringAsFixed(1)}h al ${last.percentage.toStringAsFixed(0)}% '
                      '(eq. ${last.equivalentHours.toStringAsFixed(1)}h)',
          ),
        ),
        const Divider(height: 18),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'Pagado (eq.)',
                value: '${balance.totalPaidHours.toStringAsFixed(1)} h',
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: balance.status == HourBalanceStatus.overtime
                    ? 'A favor'
                    : 'Pendiente',
                value: balance.status == HourBalanceStatus.overtime
                    ? '${balance.overtimeHours.toStringAsFixed(1)} h'
                    : '${balance.pendingHours.toStringAsFixed(1)} h',
                icon: balance.status == HourBalanceStatus.overtime
                    ? Icons.trending_up
                    : Icons.warning_amber_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: theme.textTheme.titleMedium),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 10),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
