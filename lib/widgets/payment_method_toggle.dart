import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../theme/app_theme.dart';

/// Toggle de dos opciones para elegir el método de pago.
class PaymentMethodToggle extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;

  const PaymentMethodToggle({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PaymentMethod.values.map((method) {
        final isSelected = method == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: method == PaymentMethod.efectivo ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onSelected(method),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.cardAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  method.label,
                  style: TextStyle(
                    color:
                        isSelected ? AppColors.onAccent : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
