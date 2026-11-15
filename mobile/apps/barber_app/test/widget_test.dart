import 'package:barber_app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la agenda y navega al Modo Silla', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BarberApp()));
    await tester.pumpAndSettle();

    expect(find.text('Agenda de hoy'), findsWidgets);
    expect(find.text('En línea'), findsOneWidget);
    expect(find.text('Andrés'), findsOneWidget);

    await tester.tap(find.text('Modo Silla'));
    await tester.pumpAndSettle();

    expect(find.text('Finalizar y Cobrar'), findsOneWidget);
    expect(find.text('Bloqueo rápido'), findsOneWidget);
  });

  testWidgets('navega a ganancias y ajustes', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BarberApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ganancias'));
    await tester.pumpAndSettle();
    expect(find.text('Esta semana'), findsOneWidget);
    expect(find.text(r'$ 742.300'), findsOneWidget);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('America/Bogota'), findsOneWidget);
    expect(find.text('Español (Colombia)'), findsOneWidget);
  });
}
