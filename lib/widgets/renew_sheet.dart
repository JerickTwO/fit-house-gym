import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../models/client_summary.dart';
import '../models/gym_plan.dart';
import '../models/subscription.dart';
import '../theme/app_theme.dart';
import 'payment_method_toggle.dart';
import 'plan_chips.dart';
import 'receipt_picker.dart';

/// Abre el bottom sheet de renovación rápida (2 toques) y devuelve `true`
/// si se registró el cobro.
Future<bool?> showRenewSheet(BuildContext context, ClientSummary summary) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RenewSheet(summary: summary),
  );
}

class RenewSheet extends StatefulWidget {
  final ClientSummary summary;

  const RenewSheet({super.key, required this.summary});

  @override
  State<RenewSheet> createState() => _RenewSheetState();
}

class _RenewSheetState extends State<RenewSheet> {
  List<GymPlan> _plans = [];
  GymPlan? _selectedPlan;
  PaymentMethod _selectedMethod = PaymentMethod.efectivo;
  String? _receiptImagePath;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final lastMethodLabel = widget.summary.latestSubscription?.paymentMethod;
    if (lastMethodLabel != null) {
      _selectedMethod = PaymentMethodX.fromLabel(lastMethodLabel);
    }
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final plans = await DBHelper.instance.getActivePlans();
    final lastPlanName = widget.summary.latestSubscription?.planName;
    GymPlan? preselected;
    if (lastPlanName != null) {
      for (final plan in plans) {
        if (plan.name == lastPlanName) {
          preselected = plan;
          break;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _selectedPlan = preselected ?? (plans.isNotEmpty ? plans.last : null);
      _loading = false;
    });
  }

  /// Si el plan vigente aún no vence, la renovación se encadena desde su
  /// fecha de vencimiento; si ya venció (o nunca tuvo plan), arranca hoy.
  DateTime get _startDate {
    final currentEnd = widget.summary.latestSubscription?.endDate;
    final today = DateTime.now();
    if (currentEnd != null && !currentEnd.isBefore(today)) {
      return currentEnd;
    }
    return today;
  }

  DateTime get _endDate =>
      _startDate.add(Duration(days: _selectedPlan?.durationDays ?? 0));

  Future<void> _confirmCharge() async {
    final plan = _selectedPlan;
    if (plan == null) return;
    setState(() => _saving = true);
    final now = DateTime.now();

    final subscription = Subscription(
      clientId: widget.summary.client.id!,
      planName: plan.name,
      price: plan.price,
      startDate: _startDate,
      endDate: _endDate,
      paymentMethod: _selectedMethod.label,
      createdAt: now,
      receiptImagePath: _receiptImagePath,
    );
    await DBHelper.instance.insertSubscription(subscription);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: SafeArea(
            top: false,
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.4,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        Text(
                          'Renovar · ${widget.summary.client.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Plan',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_plans.isEmpty)
                          const Text(
                            'No hay planes activos. Activa alguno en Ajustes.',
                            style: TextStyle(
                              color: AppColors.vencido,
                              fontSize: 12.5,
                            ),
                          )
                        else
                          PlanChips(
                            plans: _plans,
                            selected: _selectedPlan,
                            onSelected: (plan) =>
                                setState(() => _selectedPlan = plan),
                          ),
                        const SizedBox(height: 14),
                        if (_selectedPlan != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cardAlt,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event_available,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Nuevo vencimiento: '
                                    '${DateFormat('d MMM yyyy', 'es').format(_endDate)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Text(
                          'Método de pago',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        PaymentMethodToggle(
                          selected: _selectedMethod,
                          onSelected: (method) =>
                              setState(() => _selectedMethod = method),
                        ),
                        if (_selectedMethod == PaymentMethod.transferencia) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Comprobante (opcional)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ReceiptPicker(
                            initialPath: _receiptImagePath,
                            onChanged: (path) =>
                                setState(() => _receiptImagePath = path),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: (_saving || _selectedPlan == null)
                              ? null
                              : _confirmCharge,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.activo,
                            foregroundColor: AppColors.onAccent,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: AppColors.onAccent,
                                  ),
                                )
                              : Text(
                                  'Cobrar '
                                  '\$${(_selectedPlan?.price ?? 0).toStringAsFixed(2)}',
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
