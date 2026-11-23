import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/db_helper.dart';

/// Genera un respaldo completo de la base de datos (clientes + suscripciones)
/// y lo comparte (por ejemplo, por WhatsApp) como archivo CSV o JSON.
class ExportHelper {
  ExportHelper._internal();
  static final ExportHelper instance = ExportHelper._internal();

  String _timestamp() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
  }

  Future<void> exportAsJson() async {
    final clients = await DBHelper.instance.getAllClientsRaw();
    final subscriptions = await DBHelper.instance.getAllSubscriptionsRaw();
    final plans = await DBHelper.instance.getAllPlansRaw();

    final payload = {
      'exportado_en': DateTime.now().toIso8601String(),
      'clientes': clients,
      'suscripciones': subscriptions,
      'planes': plans,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
    final file = await _writeTempFile(
      'respaldo_gimnasio_${_timestamp()}.json',
      jsonString,
    );
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Respaldo del gimnasio (JSON)',
    );
  }

  Future<void> exportAsCsv() async {
    final clients = await DBHelper.instance.getAllClientsRaw();
    final subscriptions = await DBHelper.instance.getAllSubscriptionsRaw();
    final plans = await DBHelper.instance.getAllPlansRaw();

    final buffer = StringBuffer();

    buffer.writeln('CLIENTES');
    buffer.writeln('id,nombre,telefono,creado_en');
    for (final c in clients) {
      buffer.writeln(
        [
          c['id'],
          _csvEscape(c['name']),
          _csvEscape(c['phone']),
          c['created_at'],
        ].join(','),
      );
    }

    buffer.writeln();
    buffer.writeln('SUSCRIPCIONES');
    buffer.writeln(
      'id,cliente_id,plan,precio,fecha_inicio,fecha_fin,metodo_pago,creado_en,comprobante',
    );
    for (final s in subscriptions) {
      buffer.writeln(
        [
          s['id'],
          s['client_id'],
          _csvEscape(s['plan_name']),
          s['price'],
          s['start_date'],
          s['end_date'],
          _csvEscape(s['payment_method']),
          s['created_at'],
          _csvEscape(s['receipt_image_path']),
        ].join(','),
      );
    }

    buffer.writeln();
    buffer.writeln('PLANES');
    buffer.writeln('id,nombre,precio,duracion_dias,activo');
    for (final p in plans) {
      buffer.writeln(
        [
          p['id'],
          _csvEscape(p['name']),
          p['price'],
          p['duration_days'],
          p['active'] == 1 ? 'si' : 'no',
        ].join(','),
      );
    }

    final file = await _writeTempFile(
      'respaldo_gimnasio_${_timestamp()}.csv',
      buffer.toString(),
    );
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Respaldo del gimnasio (CSV)',
    );
  }

  String _csvEscape(Object? value) {
    final text = (value ?? '').toString();
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  Future<File> _writeTempFile(String fileName, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    return file.writeAsString(content, flush: true);
  }
}
