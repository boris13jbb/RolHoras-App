import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_routes.dart';
import '../application/manual_hours_controller.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/section_card.dart';

class HourRegistrationScreen extends ConsumerStatefulWidget {
  const HourRegistrationScreen({super.key});

  @override
  ConsumerState<HourRegistrationScreen> createState() =>
      _HourRegistrationScreenState();
}

class _HourRegistrationScreenState
    extends ConsumerState<HourRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  final _customPercentageController = TextEditingController();
  final _observationController = TextEditingController();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  DateTime _selectedDate = DateTime.now();
  double _selectedPercentage = 100;

  Widget _percentageLabel(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }

  List<DropdownMenuItem<double>> get _percentageItems => [
        DropdownMenuItem(value: 100, child: _percentageLabel('100% (x1.00)')),
        DropdownMenuItem(value: 50, child: _percentageLabel('50% (x0.50)')),
        DropdownMenuItem(value: 30, child: _percentageLabel('30% (x0.30)')),
        DropdownMenuItem(
          value: 120,
          child: _percentageLabel('Recargo 20% (x1.20)'),
        ),
        DropdownMenuItem(
          value: 125,
          child: _percentageLabel('Recargo 25% (x1.25)'),
        ),
        DropdownMenuItem(
          value: 130,
          child: _percentageLabel('Equivalencia 1→1.30 (x1.30)'),
        ),
        DropdownMenuItem(
          value: 200,
          child: _percentageLabel('Descanso: 2 días compensados (x2.00)'),
        ),
        DropdownMenuItem(
          value: 240,
          child: _percentageLabel('2 días + 20% (x2.40)'),
        ),
        DropdownMenuItem(
          value: 250,
          child: _percentageLabel('2 días + 25% (x2.50)'),
        ),
        DropdownMenuItem(value: 0, child: _percentageLabel('Personalizado')),
      ];

  @override
  void dispose() {
    _hoursController.dispose();
    _customPercentageController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Registro de horas',
      selectedIndex: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Nuevo pago de horas',
            subtitle:
                'Registra pagos manuales. Se guardan localmente en el dispositivo.',
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    key: ValueKey(_selectedDate),
                    readOnly: true,
                    initialValue: _dateFormat.format(_selectedDate),
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      hintText: 'Seleccionar fecha',
                    ),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _hoursController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad de horas',
                      prefixIcon: Icon(Icons.access_time),
                      hintText: 'Ej. 4.5',
                    ),
                    validator: _validatePositiveNumber,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<double>(
                    initialValue: _selectedPercentage,
                    isExpanded: true,
                    items: _percentageItems,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _selectedPercentage = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Porcentaje de pago',
                      prefixIcon: Icon(Icons.percent),
                    ),
                  ),
                  if (_selectedPercentage == 0) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _customPercentageController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Porcentaje personalizado',
                        prefixIcon: Icon(Icons.tune),
                        hintText: 'Ej. 75',
                      ),
                      validator: _validatePositiveNumber,
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _observationController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observación',
                      alignLabelWithHint: true,
                      hintText: 'Detalle opcional',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _savePayment,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar pago'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2),
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  String? _validatePositiveNumber(String? value) {
    final parsed = _parseNumber(value);
    if (parsed == null || parsed <= 0) {
      return 'Ingresa un valor mayor a cero';
    }
    return null;
  }

  double? _parseNumber(String? value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _savePayment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final hours = _parseNumber(_hoursController.text)!;
    final percentage = _selectedPercentage == 0
        ? _parseNumber(_customPercentageController.text)!
        : _selectedPercentage;

    ref
        .read(manualHoursControllerProvider)
        .addPayment(
          date: _selectedDate,
          hours: hours,
          percentage: percentage,
          observation: _observationController.text,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pago de horas guardado localmente')),
    );

    _hoursController.clear();
    _customPercentageController.clear();
    _observationController.clear();
    setState(() => _selectedPercentage = 100);
    context.go(AppRoutes.dashboard);
  }
}
