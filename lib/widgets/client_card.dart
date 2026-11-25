import 'package:flutter/material.dart';

import '../models/client_status.dart';
import '../models/client_summary.dart';
import '../theme/app_theme.dart';

/// Fila de cliente en la lista principal: avatar, nombre, plan, conteo de
/// días con barra de progreso, e íconos compactos de acción. Tocar la fila
/// (fuera de los íconos) abre el detalle del cliente.
class ClientCard extends StatelessWidget {
  final ClientSummary summary;
  final VoidCallback onTap;
  final VoidCallback onRenovar;
  final VoidCallback onWhatsApp;

  const ClientCard({
    super.key,
    required this.summary,
    required this.onTap,
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

  /// "Quedan 29 días" / "Vence hoy" / "Venció hace 5 días" / "Sin plan".
  String _countdownText() {
    final sub = summary.latestSubscription;
    if (sub == null) return 'Sin plan';
    final days = summary.daysLeft!;
    if (days < 0) {
      final abs = days.abs();
      return 'Venció hace $abs ${abs == 1 ? 'día' : 'días'}';
    }
    if (days == 0) return 'Vence hoy';
    return 'Quedan $days ${days == 1 ? 'día' : 'días'}';
  }

  /// Fracción de tiempo restante del período actual (0 = vence ya, 1 =
  /// recién arrancado), para la barra de progreso.
  double? _remainingFraction() {
    final sub = summary.latestSubscription;
    if (sub == null) return null;
    final status = summary.status;
    if (status == ClientStatus.vencido) return null;
    final totalDays = sub.endDate.difference(sub.startDate).inDays;
    if (totalDays <= 0) return null;
    final days = summary.daysLeft!;
    return (days / totalDays).clamp(0.0, 1.0);
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
    final fraction = _remainingFraction();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
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
                  if (summary.latestSubscription != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      summary.latestSubscription!.planName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _countdownText(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (fraction != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 4,
                        width: double.infinity,
                        child: LinearProgressIndicator(
                          value: fraction,
                          backgroundColor: AppColors.cardAlt,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconButton(
                  icon: Icons.autorenew,
                  color: AppColors.activo,
                  onTap: onRenovar,
                ),
                if (_showWhatsApp) ...[
                  const SizedBox(height: 6),
                  _IconButton(
                    icon: Icons.chat,
                    color: const Color(0xFF25D366),
                    onTap: onWhatsApp,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
