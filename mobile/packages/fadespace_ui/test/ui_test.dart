import 'package:fadespace_ui/fadespace_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('el tema usa texto de al menos 16 sp y objetivos de 48 dp', () {
    final theme = FadeSpaceTheme.light();

    expect(theme.textTheme.bodySmall?.fontSize, greaterThanOrEqualTo(16));
    expect(theme.textTheme.bodyMedium?.fontSize, greaterThanOrEqualTo(16));
    expect(theme.textTheme.bodyLarge?.fontSize, greaterThanOrEqualTo(16));
    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    expect(theme.colorScheme.brightness, Brightness.light);
  });

  testWidgets('el botón primario mide 64 dp y responde al toque', (
    tester,
  ) async {
    var pressed = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: FadeSpaceTheme.light(),
        home: Scaffold(
          body: PrimaryActionButton(
            label: 'Cliente en Silla',
            onPressed: () => pressed++,
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(FilledButton)).height, 64);

    await tester.tap(find.text('Cliente en Silla'));
    await tester.pump();

    expect(pressed, 1);
  });

  testWidgets('el botón deshabilitado no dispara y muestra carga', (
    tester,
  ) async {
    var pressed = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: FadeSpaceTheme.light(),
        home: Scaffold(
          body: PrimaryActionButton(
            label: 'Finalizar y Cobrar',
            isLoading: true,
            onPressed: () => pressed++,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Finalizar y Cobrar'));
    await tester.pump();

    expect(pressed, 0);
  });

  testWidgets('el layout no desborda a 360 px con escala de texto 1,3×', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 640),
          textScaler: TextScaler.linear(1.3),
        ),
        child: MaterialApp(
          theme: FadeSpaceTheme.light(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  const StatusPill(label: 'En línea', icon: Icons.wifi),
                  const Spacer(),
                  PrimaryActionButton(
                    label: 'Cliente en Silla',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Cliente en Silla'), findsOneWidget);
  });
}
