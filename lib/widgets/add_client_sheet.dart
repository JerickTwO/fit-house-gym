import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/client.dart';
import '../models/gym_plan.dart';
import '../models/subscription.dart';
import '../theme/app_theme.dart';
import 'payment_method_toggle.dart';
import 'plan_chips.dart';
import 'receipt_picker.dart';

/// Abre el bottom sheet de registro express y devuelve `true` si se guardó.
Future<bool?> showAddClientSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddClientSheet(),
  );
}

class AddClientSheet extends StatefulWidget {
  const AddClientSheet({super.key});

  @override
  State<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<AddClientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  List<GymPlan> _plans = [];
  GymPlan? _selectedPlan;
  PaymentMethod _selectedMethod = PaymentMethod.efectivo;
  String? _receiptImagePath;
  bool _loadingPlans = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final plans = await DBHelper.instance.getActivePlans();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _selectedPlan = plans.isNotEmpty ? plans.last : null;
      _loadingPlans = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAndCharge() async {
    if (!_formKey.currentState!.validate()) return;
    final plan = _selectedPlan;
    if (plan == null) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final client = Client(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      createdAt: now,
    );

    final clientId = await DBHelper.instance.insertClient(client);
    final endDate = now.add(Duration(days: plan.durationDays));

    final subscription = Subscription(
      clientId: clientId,
      planName: plan.name,
      price: plan.price,
      startDate: now,
      endDate: endDate,
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
            child: _loadingPlans
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Form(
                      key: _formKey,
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
                          const Text(
                            'Nuevo cliente',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            autofocus: true,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Nombre del cliente *',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El nombre es obligatorio';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'Teléfono (opcional, para WhatsApp)',
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
                          if (_selectedMethod ==
                              PaymentMethod.transferencia) ...[
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
                                : _saveAndCharge,
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
                                    'Guardar y cobrar '
                                    '\$${(_selectedPlan?.price ?? 0).toStringAsFixed(2)}',
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
