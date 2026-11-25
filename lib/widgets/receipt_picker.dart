import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../utils/receipt_image_store.dart';

/// Comprobante de transferencia opcional: tomar una foto con la cámara o
/// elegir una ya existente de la galería. Guarda la ruta local persistida.
class ReceiptPicker extends StatefulWidget {
  final String? initialPath;
  final ValueChanged<String?> onChanged;

  const ReceiptPicker({
    super.key,
    required this.initialPath,
    required this.onChanged,
  });

  @override
  State<ReceiptPicker> createState() => _ReceiptPickerState();
}

class _ReceiptPickerState extends State<ReceiptPicker> {
  String? _imagePath;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialPath;
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _working = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 70);
      if (picked == null) return;
      final persistedPath = await ReceiptImageStore.instance.persist(
        picked.path,
      );
      if (!mounted) return;
      setState(() => _imagePath = persistedPath);
      widget.onChanged(persistedPath);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo tomar/elegir la foto')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _remove() {
    setState(() => _imagePath = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    if (_working) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    if (_imagePath != null) {
      return Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(_imagePath!),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Comprobante adjunto',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _remove,
            child: const Text('Quitar',
                style: TextStyle(color: AppColors.vencido)),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pick(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: const Text('Cámara'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.cardAlt),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.image_outlined, size: 18),
            label: const Text('Galería'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.cardAlt),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
