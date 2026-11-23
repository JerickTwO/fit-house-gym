import 'package:flutter/material.dart';

import '../models/gym_plan.dart';
import '../theme/app_theme.dart';

/// Selector táctil de plan (chips) a partir de los planes activos
/// configurados en Ajustes.
class PlanChips extends StatelessWidget {
  final List<GymPlan> plans;
  final GymPlan? selected;
  final ValueChanged<GymPlan> onSelected;

  const PlanChips({
    super.key,
    required this.plans,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: plans.map((plan) {
        final isSelected = plan.id == selected?.id;
        return ChoiceChip(
          label: Text('${plan.name} \$${plan.price.toStringAsFixed(0)}'),
          selected: isSelected,
          onSelected: (_) => onSelected(plan),
          selectedColor: AppColors.accent,
          backgroundColor: AppColors.cardAlt,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.onAccent : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide.none,
          ),
        );
      }).toList(),
    );
  }
}
