import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/client_status.dart';
import '../models/client_summary.dart';
import '../theme/app_theme.dart';

/// Fila de cliente en la lista principal: avatar con iniciales, nombre,
/// estado en una sola línea y acciones directas de un toque
/// (Renovar / WhatsApp). Diseño plano, aprobado por el dueño del gimnasio.
class ClientCard extends StatelessWidget {
  final ClientSummary summary;
  final VoidCallback onRenovar;
  final VoidCallback onWhatsApp;

  const ClientCard({
    super.key,
    required this.summary,
    required this.onRenovar,
    required this.onWhatsApp,
  });

  String _initials() {
    final parts = summary.client.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  /// Texto tras el estado (p. ej. " · vence 23 dic · 30 días"), vacío si
  /// el cliente nunca tuvo un plan.
  String _statusSuffix() {
    final end = summary.latestSubscription?.endDate;
    if (end == null) return '';

    final days = summary.daysLeft!;
    final formatted = DateFormat('d MMM', 'es').format(end);
    if (days < 0) {
      final abs = days.abs();
      return ' · venció hace $abs ${abs == 1 ? 'día' : 'días'}';
    }
    if (days == 0) return ' · vence hoy';
    return ' · vence $formatted · $days días';
  }

  bool get _showWhatsApp {
    final hasPhone = summary.client.cleanPhone != null;
    final status = summary.status;
    return hasPhone &&
        (status == ClientStatus.porVencer || status == ClientStatus.vencido);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = summary.status.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accent,
            child: Text(
              _initials(),
              style: const TextStyle(
                color: AppColors.onAccent,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.client.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: summary.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: _statusSuffix(),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              _PillButton(
                icon: Icons.autorenew,
                label: 'Renovar',
                color: AppColors.activo,
                onTap: onRenovar,
              ),
              if (_showWhatsApp)
                _PillButton(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: onWhatsApp,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
      ),
    );
  }
}
