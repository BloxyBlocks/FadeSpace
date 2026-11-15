/// Errores de dominio y de transporte que la UI puede traducir a mensajes.
sealed class AppFailure implements Exception {
  const new({
    required this.code,
    required this.message,
    this.details = const <String, Object?>{},
  });

  /// Código estable compartido con la API (`SLOT_TAKEN`, `HOLD_EXPIRED`, …).
  final String code;

  /// Mensaje en español apto para el usuario final.
  final String message;

  /// Datos adicionales del error (nunca datos personales en claro).
  final Map<String, Object?> details;

  @override
  String toString() => '$code: $message';
}

final class ValidationFailure extends AppFailure {
  const new({required super.code, required super.message, super.details});
}

final class DomainFailure extends AppFailure {
  const new({required super.code, required super.message, super.details});
}

final class NetworkFailure extends AppFailure {
  const new({required super.code, required super.message, super.details});
}

final class UnauthorizedFailure extends AppFailure {
  const new({required super.code, required super.message, super.details});
}

final class UnknownFailure extends AppFailure {
  const new({required super.code, required super.message, super.details});
}
