import 'package:meta/meta.dart';

/// Dinero exacto expresado en la unidad mínima de la moneda.
///
/// Nunca usa `double`: la API y la base de datos trabajan con `DECIMAL(10,2)`.
/// Por defecto la moneda es `COP` (peso colombiano, 2 decimales).
@immutable
final class Money implements Comparable<Money> {
  const new _(this.minorUnits, this.currency);

  /// Crea un importe a partir de centavos (o la unidad mínima de la moneda).
  factory fromMinorUnits(int minorUnits, {String currency = 'COP'}) {
    _validateCurrency(currency);
    return Money._(minorUnits, currency.toUpperCase());
  }

  /// Crea un importe desde una cadena decimal, por ejemplo `"25000.50"`.
  factory parse(String value, {String currency = 'COP'}) {
    _validateCurrency(currency);

    final match = RegExp(r'^(-)?(\d+)(?:\.(\d{1,2}))?$')
        .firstMatch(value.trim());
    if (match == null) {
      throw FormatException('Importe inválido: $value');
    }

    final sign = match.group(1) == '-' ? -1 : 1;
    final whole = int.parse(match.group(2)!);
    final fraction = (match.group(3) ?? '').padRight(2, '0');
    final minorUnits = whole * 100 + int.parse(fraction);

    return Money._(sign * minorUnits, currency.toUpperCase());
  }

  factory zero({String currency = 'COP'}) {
    return Money.fromMinorUnits(0, currency: currency);
  }

  /// Unidades mínimas (centavos). Un valor de 2500050 equivale a 25000.50 COP.
  final int minorUnits;

  /// Código ISO 4217 de la moneda.
  final String currency;

  bool get isNegative => minorUnits < 0;

  bool get isZero => minorUnits == 0;

  Money operator +(Money other) {
    _ensureSameCurrency(other);
    return Money._(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _ensureSameCurrency(other);
    return Money._(minorUnits - other.minorUnits, currency);
  }

  Money operator -() => Money._(-minorUnits, currency);

  @override
  int compareTo(Money other) {
    _ensureSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  String toDecimalString() {
    final absolute = minorUnits.abs();
    final whole = absolute ~/ 100;
    final fraction = (absolute % 100).toString().padLeft(2, '0');
    final sign = isNegative ? '-' : '';
    return '$sign$whole.$fraction';
  }

  @override
  bool operator ==(Object other) {
    return other is Money &&
        other.minorUnits == minorUnits &&
        other.currency == currency;
  }

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => '$currency ${toDecimalString()}';

  void _ensureSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'No se pueden operar monedas distintas: $currency y ${other.currency}',
      );
    }
  }

  static void _validateCurrency(String currency) {
    if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(currency)) {
      throw ArgumentError('Código de moneda inválido: $currency');
    }
  }
}
