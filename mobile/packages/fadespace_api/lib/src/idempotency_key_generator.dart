import 'dart:math';

/// Genera claves de idempotencia únicas y no predecibles.
abstract interface class IdempotencyKeyGenerator {
  String generate();
}

/// Implementación basada en `Random.secure()` y marca temporal.
final class SecureIdempotencyKeyGenerator implements IdempotencyKeyGenerator {
  new({Random? random}) : _random = random ?? Random.secure();

  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  final Random _random;

  @override
  String generate() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final suffix = List<String>.generate(
      16,
      (_) => _alphabet[_random.nextInt(_alphabet.length)],
      growable: false,
    ).join();

    return 'idem-$timestamp-$suffix';
  }
}
