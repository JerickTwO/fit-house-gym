/// Métodos de pago aceptados.
/// Los planes (Diario, Semanal, Quincenal, Mensual, ...) ya no son un enum
/// fijo: son datos configurables en la tabla `plans` (ver [GymPlan]), para
/// poder activarlos, desactivarlos y modificarlos desde Ajustes.
enum PaymentMethod { efectivo, transferencia }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.efectivo:
        return 'Efectivo';
      case PaymentMethod.transferencia:
        return 'Transferencia';
    }
  }

  static PaymentMethod fromLabel(String label) {
    return PaymentMethod.values.firstWhere(
      (p) => p.label == label,
      orElse: () => PaymentMethod.efectivo,
    );
  }
}

/// Modelo de datos de una suscripción (pago/cobro) de un cliente.
class Subscription {
  final int? id;
  final int clientId;
  final String planName;
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final String paymentMethod;
  final DateTime createdAt;

  /// Ruta local (opcional) de la foto del comprobante de transferencia.
  final String? receiptImagePath;

  const Subscription({
    this.id,
    required this.clientId,
    required this.planName,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.paymentMethod,
    required this.createdAt,
    this.receiptImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'plan_name': planName,
      'price': price,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'receipt_image_path': receiptImagePath,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as int?,
      clientId: map['client_id'] as int,
      planName: map['plan_name'] as String,
      price: (map['price'] as num).toDouble(),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      paymentMethod: map['payment_method'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      receiptImagePath: map['receipt_image_path'] as String?,
    );
  }
}
