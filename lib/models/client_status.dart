import 'package:flutter/material.dart';

/// Estado de vigencia de la suscripción de un cliente.
enum ClientStatus { activo, porVencer, vencido, sinPlan }

extension ClientStatusX on ClientStatus {
  String get label {
    switch (this) {
      case ClientStatus.activo:
        return 'Activo';
      case ClientStatus.porVencer:
        return 'Por vencer';
      case ClientStatus.vencido:
        return 'Vencido';
      case ClientStatus.sinPlan:
        return 'Sin plan';
    }
  }

  /// Verde / Ámbar / Rojo tipo semáforo, gris para quien nunca se inscribió.
  Color get color {
    switch (this) {
      case ClientStatus.activo:
        return const Color(0xFF22C55E);
      case ClientStatus.porVencer:
        return const Color(0xFFF59E0B);
      case ClientStatus.vencido:
        return const Color(0xFFEF4444);
      case ClientStatus.sinPlan:
        return const Color(0xFF6B7280);
    }
  }
}

/// Calcula el estado de un cliente a partir de la fecha de vencimiento
/// de su última suscripción (comparando solo fechas, sin horas).
ClientStatus statusFromEndDate(DateTime? endDate) {
  if (endDate == null) return ClientStatus.sinPlan;
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);
  final daysLeft = end.difference(todayDate).inDays;

  if (daysLeft < 0) return ClientStatus.vencido;
  if (daysLeft <= 3) return ClientStatus.porVencer;
  return ClientStatus.activo;
}

/// Días restantes (negativos si ya venció) hasta [endDate].
int daysLeftFrom(DateTime endDate) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);
  return end.difference(todayDate).inDays;
}
