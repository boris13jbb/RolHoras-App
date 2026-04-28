import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rol_pagos_app/app.dart';
import 'package:rol_pagos_app/features/hours/application/manual_hours_controller.dart';
import 'package:rol_pagos_app/features/hours/application/hour_calculation_service.dart';
import 'package:rol_pagos_app/features/hours/domain/hour_balance.dart';
import 'package:rol_pagos_app/features/hours/domain/hour_payment.dart';

void main() {
  testWidgets('muestra el dashboard inicial', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          balanceForCurrentMonthProvider.overrideWith((ref) {
            return Stream.value(
              const HourBalanceResult(
                totalDebtHours: 0,
                totalPaidHours: 0,
                pendingHours: 0,
                overtimeHours: 0,
                status: HourBalanceStatus.pending,
              ),
            );
          }),
          paymentsForCurrentMonthProvider.overrideWith((ref) {
            return Stream.value(const <HourPayment>[]);
          }),
        ],
        child: const RolPagosApp(),
      ),
    );

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Control mensual de horas'), findsOneWidget);
    expect(find.text('Registrar pago'), findsWidgets);

    await tester.pump();
  });

  test('calcula pendiente con porcentajes equivalentes', () {
    const service = HourCalculationService();

    final result = service.calculateBalance(
      totalDebtHours: 10,
      paidEquivalentHours: [
        service.calculateEquivalentHours(hours: 4, percentage: 100),
        service.calculateEquivalentHours(hours: 4, percentage: 50),
        service.calculateEquivalentHours(hours: 3, percentage: 30),
      ],
    );

    expect(result.totalPaidHours, closeTo(6.9, 0.0001));
    expect(result.pendingHours, closeTo(3.1, 0.0001));
    expect(result.overtimeHours, 0);
    expect(result.status, HourBalanceStatus.pending);
  });

  test('calcula horas a favor cuando el pago supera la deuda', () {
    const service = HourCalculationService();

    final result = service.calculateBalance(
      totalDebtHours: 5,
      paidEquivalentHours: const [6],
    );

    expect(result.pendingHours, 0);
    expect(result.overtimeHours, 1);
    expect(result.status, HourBalanceStatus.overtime);
  });

  test('calcula equivalencias según contrato (20%, 25%, 1→1.30 y 2 días)', () {
    const service = HourCalculationService();

    // Recargos adicionales: 20% => x1.20, 25% => x1.25
    expect(
      service.calculateEquivalentHours(hours: 10, percentage: 120),
      closeTo(12.0, 0.0001),
    );
    expect(
      service.calculateEquivalentHours(hours: 10, percentage: 125),
      closeTo(12.5, 0.0001),
    );

    // Equivalencia 1 → 1.30
    expect(
      service.calculateEquivalentHours(hours: 10, percentage: 130),
      closeTo(13.0, 0.0001),
    );

    // Descanso normal: 2 días compensados => x2.00 (en horas, equivale a duplicar)
    expect(
      service.calculateEquivalentHours(hours: 8, percentage: 200),
      closeTo(16.0, 0.0001),
    );

    // 2 días + 25% => x2.50
    expect(
      service.calculateEquivalentHours(hours: 8, percentage: 250),
      closeTo(20.0, 0.0001),
    );
  });
}
