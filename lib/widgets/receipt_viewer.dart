import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// Abre el comprobante de transferencia a pantalla completa.
Future<void> showReceiptViewer(
  BuildContext context, {
  required String imagePath,
  required String clientName,
  required double price,
  required DateTime date,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ReceiptViewerScreen(
        imagePath: imagePath,
        clientName: clientName,
        price: price,
        date: date,
      ),
    ),
  );
}

class ReceiptViewerScreen extends StatelessWidget {
  final String imagePath;
  final String clientName;
  final double price;
  final DateTime date;

  const ReceiptViewerScreen({
    super.key,
    required this.imagePath,
    required this.clientName,
    required this.price,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.file(File(imagePath), fit: BoxFit.contain),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '$clientName · \$${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM yyyy', 'es').format(date),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
