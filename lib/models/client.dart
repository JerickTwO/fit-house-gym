/// Modelo de datos de un cliente del gimnasio.
class Client {
  final int? id;
  final String name;
  final String? phone;
  final DateTime createdAt;

  const Client({
    this.id,
    required this.name,
    this.phone,
    required this.createdAt,
  });

  Client copyWith({
    int? id,
    String? name,
    String? phone,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Teléfono limpio (solo dígitos) listo para anteponer el código de país.
  String? get cleanPhone {
    if (phone == null || phone!.trim().isEmpty) return null;
    var digits = phone!.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    // Si viene con el 0 inicial típico de Ecuador (09XXXXXXXX), se quita.
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }
}
