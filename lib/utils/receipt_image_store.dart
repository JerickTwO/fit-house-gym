import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Copia la foto elegida (cámara o galería) a una carpeta permanente de la
/// app, porque la ruta que entrega el selector puede vivir en caché
/// temporal y borrarse en cualquier momento.
class ReceiptImageStore {
  ReceiptImageStore._internal();
  static final ReceiptImageStore instance = ReceiptImageStore._internal();

  Future<String> persist(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${docsDir.path}/comprobantes');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    final extension = sourcePath.contains('.')
        ? sourcePath.split('.').last
        : 'jpg';
    final fileName =
        'comprobante_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final destination = File('${receiptsDir.path}/$fileName');

    await File(sourcePath).copy(destination.path);
    return destination.path;
  }

  Future<void> delete(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
