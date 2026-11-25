import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/gym_plan.dart';
import '../theme/app_theme.dart';
import '../utils/export_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _PlanControllers {
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController duration;

  _PlanControllers(GymPlan plan)
      : name = TextEditingController(text: plan.name),
        price = TextEditingController(text: plan.price.toStringAsFixed(2)),
        duration = TextEditingController(text: plan.durationDays.toString());

  void dispose() {
    name.dispose();
    price.dispose();
    duration.dispose();
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<GymPlan> _plans = [];
  final Map<int, _PlanControllers> _controllers = {};
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPlans() async {
    final plans = await DBHelper.instance.getAllPlans();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    for (final plan in plans) {
      _controllers[plan.id!] = _PlanControllers(plan);
    }
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _loading = false;
    });
  }

  Future<void> _savePlan(GymPlan plan) async {
    final controllers = _controllers[plan.id]!;
    final name = controllers.name.text.trim();
    final price = double.tryParse(controllers.price.text.replaceAll(',', '.'));
    final duration = int.tryParse(controllers.duration.text);

    if (name.isEmpty ||
        price == null ||
        price < 0 ||
        duration == null ||
        duration < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa nombre, precio y duración')),
      );
      return;
    }

    await DBHelper.instance.updatePlan(
      plan.copyWith(name: name, price: price, durationDays: duration),
    );
    await _loadPlans();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan "$name" actualizado')),
    );
  }

  Future<void> _toggleActive(GymPlan plan, bool value) async {
    if (!value) {
      final activeCount = _plans.where((p) => p.active).length;
      if (activeCount <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe quedar al menos un plan activo'),
          ),
        );
        return;
      }
    }
    await DBHelper.instance.setPlanActive(plan.id!, value);
    await _loadPlans();
  }

  Future<void> _export(Future<void> Function() action) async {
    setState(() => _exporting = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo exportar el respaldo')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Planes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Actívalos, desactívalos o modifica nombre, precio y '
                  'duración. Un plan desactivado deja de ofrecerse, pero no '
                  'borra el historial de cobros ya hechos con él.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                ..._plans.map((plan) => _PlanCard(
                      plan: plan,
                      controllers: _controllers[plan.id]!,
                      onToggleActive: (value) => _toggleActive(plan, value),
                      onSave: () => _savePlan(plan),
                    )),
                const SizedBox(height: 28),
                const Text(
                  'Respaldo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Exporta todos tus datos y compártelos por WhatsApp como copia de seguridad.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _exporting
                      ? null
                      : () => _export(ExportHelper.instance.exportAsCsv),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Exportar como CSV'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.cardAlt),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _exporting
                      ? null
                      : () => _export(ExportHelper.instance.exportAsJson),
                  icon: const Icon(Icons.data_object),
                  label: const Text('Exportar como JSON'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.cardAlt),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                if (_exporting) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final GymPlan plan;
  final _PlanControllers controllers;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onSave;

  const _PlanCard({
    required this.plan,
    required this.controllers,
    required this.onToggleActive,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.active ? plan.name : '${plan.name} (inactivo)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: plan.active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Switch(
                  value: plan.active,
                  onChanged: onToggleActive,
                  activeTrackColor: AppColors.accent,
                  thumbColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? AppColors.onAccent
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controllers.name,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers.price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixText: '\$ ',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controllers.duration,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duración (días)',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.check_circle, color: AppColors.activo),
                label: const Text(
                  'Guardar',
                  style: TextStyle(color: AppColors.activo),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
