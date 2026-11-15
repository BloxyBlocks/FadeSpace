import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fadespace_api/src/idempotency_key_generator.dart';
import 'package:fadespace_core/fadespace_core.dart';

/// Configuración del cliente HTTP.
final class ApiConfig {
  const new({
    required this.baseUrl,
    this.tenantDomain,
    this.clientVersion = '0.1.0',
  });

  final String baseUrl;

  /// Dominio del tenant resuelto por la PWA (nunca se envía `tenant_id`).
  final String? tenantDomain;

  final String clientVersion;
}

/// Obtiene el token vigente (Sanctum o token de cliente Zero-Login).
typedef TokenProvider = Future<String?> Function();

/// Error tipado que envuelve un fallo de dominio listo para la UI.
final class ApiException implements Exception {
  const new(this.failure);

  final AppFailure failure;

  @override
  String toString() => failure.toString();
}

/// Cliente del API `/api/v1` de FadeSpace.
final class FadeSpaceApiClient {
  new({
    required ApiConfig config,
    Dio? dio,
    this._tokenProvider,
    IdempotencyKeyGenerator? idempotencyKeyGenerator,
  }) : _config = config,
       _idempotencyKeys =
           idempotencyKeyGenerator ?? SecureIdempotencyKeyGenerator(),
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.baseUrl,
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 15),
               contentType: Headers.jsonContentType,
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Accept'] = Headers.jsonContentType;
          options.headers['X-Client-Version'] = _config.clientVersion;

          final tenantDomain = _config.tenantDomain;
          if (tenantDomain != null && tenantDomain.isNotEmpty) {
            options.headers['X-Tenant-Domain'] = tenantDomain;
          }

          final token = await _tokenProvider?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (error, handler) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: mapDioException(error),
              stackTrace: error.stackTrace,
            ),
          );
        },
      ),
    );
  }

  final ApiConfig _config;
  final TokenProvider? _tokenProvider;
  final IdempotencyKeyGenerator _idempotencyKeys;
  final Dio _dio;

  Future<Map<String, Object?>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    final response = await _request<Map<String, Object?>>(
      () => _dio.get<Object?>(path, queryParameters: query),
    );

    return _asMap(response.data);
  }

  Future<Map<String, Object?>> postJson(
    String path, {
    Object? body,
    String? idempotencyKey,
  }) async {
    final response = await _request<Map<String, Object?>>(
      () => _dio.post<Object?>(
        path,
        data: body,
        options: Options(
          headers: <String, Object?>{
            'Idempotency-Key': idempotencyKey ?? _idempotencyKeys.generate(),
          },
        ),
      ),
    );

    return _asMap(response.data);
  }

  Future<void> delete(String path, {String? idempotencyKey}) async {
    await _request<Object?>(
      () => _dio.delete<Object?>(
        path,
        options: Options(
          headers: <String, Object?>{'Idempotency-Key': ?idempotencyKey},
        ),
      ),
    );
  }

  Future<Response<T>> _request<T>(
    Future<Response<Object?>> Function() send,
  ) async {
    try {
      final response = await send();
      return Response<T>(
        requestOptions: response.requestOptions,
        data: response.data as T?,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        headers: response.headers,
      );
    } on DioException catch (error) {
      final failure = error.error;
      throw ApiException(
        failure is AppFailure ? failure : mapDioException(error),
      );
    }
  }

  Map<String, Object?> _asMap(Object? data) {
    if (data is Map<String, Object?>) {
      return data;
    }

    if (data is Map) {
      return data.map<String, Object?>(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return <String, Object?>{};
  }
}

/// Traduce un error de Dio a un fallo de dominio tipado.
AppFailure mapDioException(DioException error) {
  final response = error.response;

  if (response == null) {
    return const NetworkFailure(
      code: 'NETWORK_ERROR',
      message: 'No se pudo conectar con FadeSpace. Intenta de nuevo.',
    );
  }

  final data = response.data;
  final body = data is Map ? data : const <Object?, Object?>{};
  final code = body['code'];
  final message = body['message'];
  final details = body['details'];
  final status = response.statusCode ?? 0;

  final normalizedCode = code is String ? code : 'HTTP_$status';
  final normalizedMessage = message is String
      ? message
      : 'Ocurrió un error inesperado. Intenta de nuevo.';
  final normalizedDetails = details is Map
      ? details.map<String, Object?>(
          (key, value) => MapEntry(key.toString(), value),
        )
      : const <String, Object?>{};

  if (status == 401 || status == 403) {
    return UnauthorizedFailure(
      code: normalizedCode,
      message: normalizedMessage,
      details: normalizedDetails,
    );
  }

  if (status == 422) {
    return ValidationFailure(
      code: normalizedCode,
      message: normalizedMessage,
      details: normalizedDetails,
    );
  }

  if (status >= 400 && status < 500) {
    return DomainFailure(
      code: normalizedCode,
      message: normalizedMessage,
      details: normalizedDetails,
    );
  }

  return UnknownFailure(
    code: normalizedCode,
    message: normalizedMessage,
    details: normalizedDetails,
  );
}
