import 'package:fadespace_core/fadespace_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('parsea importes exactos con dos decimales', () {
      expect(Money.parse('25000.50').minorUnits, 2500050);
      expect(Money.parse('0').toDecimalString(), '0.00');
      expect(Money.parse('-1500.05').toDecimalString(), '-1500.05');
      expect(Money.parse('12.5').toDecimalString(), '12.50');
    });

    test('rechaza formatos inválidos', () {
      expect(() => Money.parse('12,50'), throwsFormatException);
      expect(() => Money.parse('1.234'), throwsFormatException);
      expect(() => Money.parse('abc'), throwsFormatException);
    });

    test('suma y resta conservando la moneda', () {
      final a = Money.parse('10000.00');
      final b = Money.parse('2500.50');

      expect((a + b).toDecimalString(), '12500.50');
      expect((a - b).toDecimalString(), '7499.50');
      expect((-a).toDecimalString(), '-10000.00');
      expect(a + b, Money.parse('12500.50'));
    });

    test('no mezcla monedas distintas', () {
      final cop = Money.parse('1000.00');
      final usd = Money.parse('1000.00', currency: 'USD');

      expect(() => cop + usd, throwsArgumentError);
      expect(cop.currency, 'COP');
      expect(usd.currency, 'USD');
    });

    test('compara importes del mismo tipo', () {
      expect(Money.parse('10.00').compareTo(Money.parse('10.00')), 0);
      expect(Money.parse('9.99').compareTo(Money.parse('10.00')), lessThan(0));
    });
  });

  group('Result', () {
    test('expone valor en caso de éxito', () {
      const result = Ok<int>(7);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, 7);
      expect(result.failureOrNull, isNull);
    });

    test('expone el error de dominio en caso de fallo', () {
      const failure = DomainFailure(
        code: 'SLOT_TAKEN',
        message: 'La franja ya fue tomada.',
      );
      const result = Err<int>(failure);

      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull?.code, 'SLOT_TAKEN');
    });
  });
}
