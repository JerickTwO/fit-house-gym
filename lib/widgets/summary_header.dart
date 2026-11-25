import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Resumen superior compacto: cobros de hoy y conteo de activos/vencidos.
/// Diseño plano (sin tarjeta), aprobado por el dueño del gimnasio.
class SummaryHeader extends StatelessWidget {
  final double totalEfectivo;
  final double totalTransferencia;
  final int activos;
  final int porVencer;
  final int vencidos;

  const SummaryHeader({
    super.key,
    required this.totalEfectivo,
    required this.totalTransferencia,
    required this.activos,
    required this.porVencer,
    required this.vencidos,
  });

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final totalHoy = totalEfectivo + totalTransferencia;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cobrado hoy',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _money(totalHoy),
          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          'Efectivo ${_money(totalEfectivo)} · Transferencia ${_money(totalTransferencia)}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatBox(
                label: 'Activos', value: activos, dotColor: AppColors.activo),
            const SizedBox(width: 10),
            _StatBox(
                label: 'Por vencer',
                value: porVencer,
                dotColor: AppColors.porVencer),
            const SizedBox(width: 10),
            _StatBox(
                label: 'Vencidos',
                value: vencidos,
                dotColor: AppColors.vencido),
          ],
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final Color dotColor;

  const _StatBox({
    required this.label,
    required this.value,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
