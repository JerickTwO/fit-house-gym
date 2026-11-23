/// Plan de suscripción configurable desde Ajustes: se puede activar,
/// desactivar, renombrar, cambiar precio y duración.
class GymPlan {
  final int? id;
  final String name;
  final double price;
  final int durationDays;
  final bool active;
  final int sortOrder;

  const GymPlan({
    this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.active,
    required this.sortOrder,
  });

  GymPlan copyWith({
    int? id,
    String? name,
    double? price,
    int? durationDays,
    bool? active,
    int? sortOrder,
  }) {
    return GymPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      durationDays: durationDays ?? this.durationDays,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'duration_days': durationDays,
      'active': active ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory GymPlan.fromMap(Map<String, dynamic> map) {
    return GymPlan(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      durationDays: map['duration_days'] as int,
      active: (map['active'] as int) == 1,
      sortOrder: map['sort_order'] as int,
    );
  }
}
