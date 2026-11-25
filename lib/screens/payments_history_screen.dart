import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../models/payment_record.dart';
import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../widgets/receipt_viewer.dart';

enum _Period { esteMes, todo }

enum _MethodFilter { todos, efectivo, transferencia }

/// Historial general de pagos de todos los clientes: agrupado por fecha,
/// filtrable por período y método, con acceso a la foto del comprobante.
class PaymentsHistoryScreen extends StatefulWidget {
  const PaymentsHistoryScreen({super.key});

  @override
  State<PaymentsHistoryScreen> createState() => _PaymentsHistoryScreenState();
}

class _PaymentsHistoryScreenState extends State<PaymentsHistoryScreen> {
  List<PaymentRecord> _payments = [];
  _Period _period = _Period.esteMes;
  _MethodFilter _method = _MethodFilter.todos;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    DateTime? since;
    if (_period == _Period.esteMes) {
      final now = DateTime.now();
      since = DateTime(now.year, now.month, 1);
    }
    String? methodLabel;
    switch (_method) {
      case _MethodFilter.todos:
        methodLabel = null;
      case _MethodFilter.efectivo:
        methodLabel = PaymentMethod.efectivo.label;
      case _MethodFilter.transferencia:
        methodLabel = PaymentMethod.transferencia.label;
    }
    final payments = await DBHelper.instance.getPayments(
      since: since,
      paymentMethod: methodLabel,
    );
    if (!mounted) return;
    setState(() {
      _payments = payments;
      _loading = false;
    });
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) return 'Hoy';
    return DateFormat('d MMM yyyy', 'es').format(date);
  }

  Map<String, List<PaymentRecord>> _groupedByDay() {
    final grouped = <String, List<PaymentRecord>>{};
    for (final payment in _payments) {
      final key = _dayLabel(payment.createdAt);
      grouped.putIfAbsent(key, () => []).add(payment);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedByDay();

    return Scaffold(
      appBar: AppBar(title: const Text('Pagos cobrados')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: _Dropdown<_Period>(
                    value: _period,
                    items: const {
                      _Period.esteMes: 'Este mes',
                      _Period.todo: 'Todo',
                    },
                    onChanged: (value) {
                      setState(() => _period = value);
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Dropdown<_MethodFilter>(
                    value: _method,
                    items: const {
                      _MethodFilter.todos: 'Todos',
                      _MethodFilter.efectivo: 'Efectivo',
                      _MethodFilter.transferencia: 'Transferencia',
                    },
                    onChanged: (value) {
                      setState(() => _method = value);
                      _loadData();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _payments.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin pagos registrados con este filtro',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        children: grouped.entries.expand((entry) {
                          return [
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8, top: 10),
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ...entry.value.map((p) => _PaymentTile(payment: p)),
                          ];
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.card,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
            size: 18,
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          items: items.entries
              .map(
                (e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentRecord payment;

  const _PaymentTile({required this.payment});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasReceipt = payment.receiptImagePath != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accent,
            child: Text(
              _initials(payment.clientName),
              style: const TextStyle(
                color: AppColors.onAccent,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.clientName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${payment.planName} · ${payment.paymentMethod}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${payment.price.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          if (hasReceipt) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => showReceiptViewer(
                context,
                imagePath: payment.receiptImagePath!,
                clientName: payment.clientName,
                price: payment.price,
                date: payment.createdAt,
              ),
              child: Container(
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
        ],
      ),
    );
  }
}
