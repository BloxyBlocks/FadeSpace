import 'package:material_ui/material_ui.dart';

/// Tema Material 3 de FadeSpace.
///
/// Mobile-first: base de 360 px, texto mínimo de 16 sp, objetivos táctiles
/// de al menos 48 dp y alto contraste para el Modo Silla.
abstract final class FadeSpaceTheme {
  static const Color seedColor = Color(0xFF0F5132);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: base.textTheme.copyWith(
        bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 16),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 16),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 18),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 18),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 22),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontSize: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
