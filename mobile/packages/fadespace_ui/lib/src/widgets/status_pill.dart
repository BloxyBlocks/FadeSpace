import 'package:material_ui/material_ui.dart';

/// Etiqueta compacta para estados operativos (en línea, en silla, espera…).
class StatusPill extends StatelessWidget {
  const new({required this.label, this.color, this.icon, super.key});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 18, color: effectiveColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
