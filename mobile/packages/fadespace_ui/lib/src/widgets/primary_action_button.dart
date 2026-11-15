import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Botón de acción primaria del Modo Silla.
///
/// 64 dp de alto, texto grande y respuesta háptica para operar con una mano.
class PrimaryActionButton extends StatelessWidget {
  const new({
    required this.label,
    this.onPressed,
    this.icon = Icons.check_circle_outline,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: FilledButton.icon(
        onPressed: isLoading
            ? null
            : () {
                unawaited(HapticFeedback.mediumImpact());
                onPressed?.call();
              },
        icon: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Icon(icon, size: 26),
        label: Text(label, textAlign: TextAlign.center),
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          minimumSize: const Size.fromHeight(64),
        ),
      ),
    );
  }
}
