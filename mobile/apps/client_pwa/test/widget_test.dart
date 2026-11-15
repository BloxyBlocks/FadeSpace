import 'package:client_pwa/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el flujo de reserva y confirma la cita', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ClientPwaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Reserva tu cita'), findsOneWidget);
    expect(find.text('Servicio'), findsOneWidget);
    expect(find.text('Tus datos'), findsOneWidget);

    final confirm = find.text('Confirmar reserva');
    await tester.scrollUntilVisible(confirm, 300);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.text('¡Cita confirmada!'), findsWidgets);

    await tester.tap(find.text('Mi cita'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmada'), findsOneWidget);
    expect(find.text('12 min'), findsOneWidget);
  });

  testWidgets('permite elegir servicio, barbero y franja', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ClientPwaApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Corte + barba'));
    await tester.pump();
    await tester.tap(find.text('Camilo'));
    await tester.pump();
    await tester.tap(find.text('12:30 p. m.'));
    await tester.pump();

    final confirm = find.text('Confirmar reserva');
    await tester.scrollUntilVisible(confirm, 300);
    expect(confirm, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
