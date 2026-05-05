import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/year_month.dart';
import '../../../shared/widgets/section_card.dart';
import '../../payroll/application/latest_payroll_comparison_provider.dart';
import '../../payroll/application/payroll_reconciliation.dart';

/// Panel principal: último rol importado vs registros del **mismo mes** que el rol.
class DashboardLastPayrollSection extends StatelessWidget {
  const DashboardLastPayrollSection({
    required this.asyncValue,
    super.key,
  });

  final AsyncValue<LatestPayrollComparison?> asyncValue;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => SectionCard(
        title: 'Último rol de pago',
        subtitle:
            'Comparación PDF vs tus horas (deuda, compensadas y saldo pendiente).',
        child: const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => SectionCard(
        title: 'Último rol de pago',
        subtitle: 'No se pudo cargar la comparación.',
        child: SelectableText('$error'),
      ),
      data: (data) => _buildData(context, data),
    );
  }

  Widget _buildData(BuildContext context, LatestPayrollComparison? data) {
    final theme = Theme.of(context);

    if (data == null) {
      return SectionCard(
        title: 'Último rol de pago',
        subtitle:
            'Cuando importes un PDF en Historial, aquí verás PDF vs tus datos para el mes del rol.',
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.payrollHistory),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Ir a Historial'),
          ),
        ),
      );
    }

    final payroll = data.payroll;
    final balance = data.balance;
    final rows = buildPayrollReconciliationRows(
      payroll: payroll,
      balance: balance,
    );
    final hasComparable = payrollHasComparableDetections(payroll);
    final issues = hasComparable
        ? payrollReconciliationIssues(payroll, balance)
        : <String>[];

    final nowYm = YearMonth.fromDate(DateTime.now());
    final sameMonthCalendar =
        data.yearMonth.year == nowYm.year && data.yearMonth.month == nowYm.month;

    final periodLabel =
        '${payroll.month.toString().padLeft(2, '0')}/${payroll.year} · ${payroll.fileName}';

    return SectionCard(
      title: 'Último rol de pago vs tu registro',
      subtitle: periodLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!sameMonthCalendar)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esta tabla es el mes ${data.yearMonth.month}/${data.yearMonth.year} '
                          '(el del rol). Las tarjetas de resumen siguientes muestran el mes actual (${nowYm.month}/${nowYm.year}), salvo que coincidan.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!hasComparable)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      color: theme.colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este PDF no tiene horas detectadas. Abre Historial → Procesar (o vuelve a importar tras actualizar la app).',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          if (issues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.shade200,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.compare_arrows, color: Colors.orange.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${issues.length} diferencia${issues.length == 1 ? '' : 's'} respecto al PDF. Actualiza la deuda y los pagos del mes ${data.yearMonth.month}/${data.yearMonth.year} para alinearlos.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.1),
              1: FlexColumnWidth(1.35),
              2: FlexColumnWidth(1.35),
              3: IntrinsicColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor,
                    ),
                  ),
                ),
                children: [
                  _cellHeader(context, 'Concepto'),
                  _cellHeader(context, 'PDF (rol)', align: TextAlign.end),
                  _cellHeader(context, 'Tu app', align: TextAlign.end),
                  _cellHeader(context, '', align: TextAlign.center),
                ],
              ),
              for (final row in rows)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.concept,
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (row.subtitle != null)
                            Text(
                              row.subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _cellBody(
                      context,
                      row.hasPdfValue ? '${row.pdfDisplay} h' : '—',
                      align: TextAlign.end,
                      emphasize: row.hasPdfValue,
                    ),
                    _cellBody(
                      context,
                      '${row.appDisplay} h',
                      align: TextAlign.end,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        !row.hasPdfValue
                            ? Icons.remove_circle_outline
                            : (row.matches
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_outlined),
                        size: 22,
                        color: !row.hasPdfValue
                            ? theme.disabledColor
                            : (row.matches ? Colors.green : Colors.orange),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.payrollHistory),
              icon: const Icon(Icons.history),
              label: const Text('Ver historial de roles'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cellHeader(
    BuildContext context,
    String text, {
    TextAlign align = TextAlign.start,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        textAlign: align,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _cellBody(
    BuildContext context,
    String text, {
    required TextAlign align,
    bool emphasize = true,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: emphasize
            ? theme.textTheme.titleMedium
            : theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
