import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../models/client.dart';
import '../models/client_status.dart';
import '../models/client_summary.dart';
import '../models/payment_record.dart';
import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../widgets/receipt_viewer.dart';
import '../widgets/renew_sheet.dart';

enum _MethodFilter { todo, efectivo, transferencia }

/// Pantalla de detalle de un cliente: datos, cuenta regresiva de la
/// suscripción vigente, historial de pagos filtrable y acciones
/// (renovar, eliminar cliente).
class ClientDetailScreen extends StatefulWidget {
  final Client client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  Subscription? _latestSubscription;
  List<PaymentRecord> _payments = [];
  _MethodFilter _filter = _MethodFilter.todo;
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final latest = await DBHelper.instance.getLatestSubscription(
      widget.client.id!,
    );
    final payments = await DBHelper.instance.getPayments(
      clientId: widget.client.id!,
    );
    if (!mounted) return;
    setState(() {
      _latestSubscription = latest;
      _payments = payments;
      _loading = false;
    });
  }

  List<PaymentRecord> get _filteredPayments {
    switch (_filter) {
      case _MethodFilter.todo:
        return _payments;
      case _MethodFilter.efectivo:
        return _payments
            .where((p) => p.paymentMethod == PaymentMethod.efectivo.label)
            .toList();
      case _MethodFilter.transferencia:
        return _payments
            .where(
              (p) => p.paymentMethod == PaymentMethod.transferencia.label,
            )
            .toList();
    }
  }

  Future<void> _onRenovar() async {
    final summary = ClientSummary(
      client: widget.client,
      latestSubscription: _latestSubscription,
    );
    final result = await showRenewSheet(context, summary);
    if (result == true) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renovación registrada')),
      );
    }
  }

  Future<void> _onDelete() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.vencido.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.vencido,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '¿Eliminar a ${widget.client.name}?',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Se borrará el cliente y todo su historial de pagos de este '
              'dispositivo. Esta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.cardAlt),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vencido.withValues(
                        alpha: 0.14,
                      ),
                      foregroundColor: AppColors.vencido,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() => _deleting = true);
    await DBHelper.instance.deleteClient(widget.client.id!);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _countdownText() {
    final sub = _latestSubscription;
    if (sub == null) return 'Sin suscripción registrada';
    final status = statusFromEndDate(sub.endDate);
    final days = daysLeftFrom(sub.endDate);
    if (status == ClientStatus.vencido) {
      final abs = days.abs();
      return 'Venció hace $abs ${abs == 1 ? 'día' : 'días'}';
    }
    if (days == 0) return 'Vence hoy';
    return 'Quedan $days ${days == 1 ? 'día' : 'días'}';
  }

  double? _remainingFraction() {
    final sub = _latestSubscription;
    if (sub == null) return null;
    final status = statusFromEndDate(sub.endDate);
    if (status == ClientStatus.vencido) return null;
    final totalDays = sub.endDate.difference(sub.startDate).inDays;
    if (totalDays <= 0) return null;
    final days = daysLeftFrom(sub.endDate);
    return (days / totalDays).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final sub = _latestSubscription;
    final status =
        sub == null ? ClientStatus.sinPlan : statusFromEndDate(sub.endDate);
    final fraction = _remainingFraction();
    final payments = _filteredPayments;
    final total = payments.fold<double>(0, (sum, p) => sum + p.price);
    final withReceipt =
        payments.where((p) => p.receiptImagePath != null).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del cliente')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          widget.client.name.isEmpty
                              ? '?'
                              : widget.client.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.onAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.client.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (widget.client.phone != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '📞 ${widget.client.phone}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (sub != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${sub.planName} · \$${sub.price.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'vence ${DateFormat('d MMM', 'es').format(sub.endDate)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _countdownText(),
                          style: TextStyle(
                            color: status.color,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (fraction != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 6,
                              backgroundColor: AppColors.cardAlt,
                              valueColor: AlwaysStoppedAnimation(status.color),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Historial de pagos',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _FilterTab(
                      label: 'Todo',
                      selected: _filter == _MethodFilter.todo,
                      onTap: () => setState(() => _filter = _MethodFilter.todo),
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: 'Efectivo',
                      selected: _filter == _MethodFilter.efectivo,
                      onTap: () =>
                          setState(() => _filter = _MethodFilter.efectivo),
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: 'Transferencia',
                      selected: _filter == _MethodFilter.transferencia,
                      onTap: () => setState(
                        () => _filter = _MethodFilter.transferencia,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _SummaryStat(
                          label: 'Total',
                          value: '\$${total.toStringAsFixed(2)}'),
                      _SummaryStat(label: 'Pagos', value: '${payments.length}'),
                      _SummaryStat(
                        label: 'Comprobantes',
                        value: '$withReceipt',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (payments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Sin pagos registrados con este filtro',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...payments.map(
                    (p) => _PaymentRow(
                      payment: p,
                      onTapReceipt: p.receiptImagePath == null
                          ? null
                          : () => showReceiptViewer(
                                context,
                                imagePath: p.receiptImagePath!,
                                clientName: p.clientName,
                                price: p.price,
                                date: p.createdAt,
                              ),
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _onRenovar,
                  icon: const Icon(Icons.autorenew),
                  label: const Text('Renovar suscripción'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _deleting ? null : _onDelete,
                  icon: _deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: const Text('Eliminar cliente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.vencido,
                    side: const BorderSide(color: Color(0x80EF4444)),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.cardAlt : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.cardAlt),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final PaymentRecord payment;
  final VoidCallback? onTapReceipt;

  const _PaymentRow({required this.payment, required this.onTapReceipt});

  @override
  Widget build(BuildContext context) {
    final isTransferencia =
        payment.paymentMethod == PaymentMethod.transferencia.label;
    final methodColor =
        isTransferencia ? const Color(0xFF60A5FA) : AppColors.activo;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment.planName} · \$${payment.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      payment.paymentMethod,
                      style: TextStyle(
                        color: methodColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                    Text(
                      ' · ${DateFormat('d MMM yyyy', 'es').format(payment.createdAt)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isTransferencia)
            GestureDetector(
              onTap: onTapReceipt,
              child: onTapReceipt == null
                  ? const Text(
                      'Sin foto',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    )
                  : Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
