import 'client.dart';
import 'client_status.dart';
import 'subscription.dart';

/// Combina un cliente con su última suscripción (si existe) para
/// pintar la lista principal sin hacer una consulta por tarjeta.
class ClientSummary {
  final Client client;
  final Subscription? latestSubscription;

  const ClientSummary({required this.client, this.latestSubscription});

  ClientStatus get status => statusFromEndDate(latestSubscription?.endDate);

  int? get daysLeft {
    final end = latestSubscription?.endDate;
    if (end == null) return null;
    return daysLeftFrom(end);
  }
}
