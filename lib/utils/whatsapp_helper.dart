import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/client.dart';
import '../models/client_status.dart';

/// Abre WhatsApp con un mensaje prellenado recordando el vencimiento.
Future<bool> openWhatsAppReminder({
  required Client client,
  required DateTime endDate,
}) async {
  final phone = client.cleanPhone;
  if (phone == null) return false;

  final status = statusFromEndDate(endDate);
  final formattedDate = DateFormat("d 'de' MMMM", 'es').format(endDate);

  final message = status == ClientStatus.vencido
      ? 'Hola ${client.name}! 👋 Te escribimos del gimnasio: tu suscripción '
            'venció el $formattedDate. Te esperamos para renovarla cuando puedas. 💪'
      : 'Hola ${client.name}! 👋 Te recordamos que tu suscripción del '
            'gimnasio vence el $formattedDate. ¡No te quedes sin entrenar! 💪';

  final uri = Uri.parse(
    'https://wa.me/593$phone?text=${Uri.encodeComponent(message)}',
  );

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
