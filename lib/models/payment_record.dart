/// Un pago (suscripción cobrada) con el nombre del cliente ya resuelto,
/// para listarlo en el historial general o en el de un cliente puntual.
class PaymentRecord {
  final int subscriptionId;
  final int clientId;
  final String clientName;
  final String planName;
  final double price;
  final String paymentMethod;
  final DateTime createdAt;
  final String? receiptImagePath;

  const PaymentRecord({
    required this.subscriptionId,
    required this.clientId,
    required this.clientName,
    required this.planName,
    required this.price,
    required this.paymentMethod,
    required this.createdAt,
    this.receiptImagePath,
  });

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      subscriptionId: map['id'] as int,
      clientId: map['client_id'] as int,
      clientName: map['client_name'] as String,
      planName: map['plan_name'] as String,
      price: (map['price'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      receiptImagePath: map['receipt_image_path'] as String?,
    );
  }
}
