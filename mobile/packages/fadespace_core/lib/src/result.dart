import 'package:fadespace_core/src/failure.dart';

/// Resultado explícito: éxito con valor o error de dominio.
sealed class Result<T> {
  const new();

  bool get isOk => this is Ok<T>;

  T? get valueOrNull {
    final result = this;
    return result is Ok<T> ? result.value : null;
  }

  AppFailure? get failureOrNull {
    final result = this;
    return result is Err<T> ? result.failure : null;
  }
}

final class Ok<T> extends Result<T> {
  const new(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const new(this.failure);

  final AppFailure failure;
}
