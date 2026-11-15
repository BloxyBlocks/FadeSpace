import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fadespace_api/fadespace_api.dart';
import 'package:fadespace_core/fadespace_core.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeAdapter implements HttpClientAdapter {
  new(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

FadeSpaceApiClient _clientWith(
  Future<ResponseBody> Function(RequestOptions options) handler, {
  String? token,
  String tenantDomain = 'barberia.fadespace.test',
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.fadespace.test'))
    ..httpClientAdapter = _FakeAdapter(handler);

  return FadeSpaceApiClient(
    config: ApiConfig(
      baseUrl: 'https://api.fadespace.test',
      tenantDomain: tenantDomain,
    ),
    dio: dio,
    tokenProvider: () async => token,
    idempotencyKeyGenerator: _FixedKeyGenerator(),
  );
}

final class _FixedKeyGenerator implements IdempotencyKeyGenerator {
  @override
  String generate() => 'idem-fixed-key';
}

void main() {
  test('envía tenant, versión, token y acepta JSON', () async {
    late RequestOptions captured;
    final client = _clientWith((options) async {
      captured = options;
      return _json(<String, Object?>{'id': 'tenant-1'});
    }, token: 'token-abc');

    final body = await client.getJson('/api/v1/public/tenant');

    expect(body['id'], 'tenant-1');
    expect(captured.headers['X-Tenant-Domain'], 'barberia.fadespace.test');
    expect(captured.headers['X-Client-Version'], '0.1.0');
    expect(captured.headers['Authorization'], 'Bearer token-abc');
    expect(captured.headers['Accept'], Headers.jsonContentType);
  });

  test('genera Idempotency-Key en POST y respeta la clave explícita', () async {
    final keys = <Object?>[];
    final client = _clientWith((options) async {
      keys.add(options.headers['Idempotency-Key']);
      return _json(<String, Object?>{'ok': true});
    });

    await client.postJson('/api/v1/public/appointments');
    await client.postJson(
      '/api/v1/public/appointments',
      idempotencyKey: 'idem-retry-1',
    );

    expect(keys, <Object?>['idem-fixed-key', 'idem-retry-1']);
  });

  test('traduce SLOT_TAKEN a un fallo de dominio', () async {
    final client = _clientWith(
      (_) async => _json(<String, Object?>{
        'code': 'SLOT_TAKEN',
        'message': 'La franja ya fue tomada.',
        'details': <String, Object?>{'slot': '10:00'},
      }, statusCode: 409),
    );

    await expectLater(
      client.postJson('/api/v1/public/appointments'),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.failure,
          'failure',
          isA<DomainFailure>()
              .having((failure) => failure.code, 'code', 'SLOT_TAKEN')
              .having(
                (failure) => failure.message,
                'message',
                'La franja ya fue tomada.',
              ),
        ),
      ),
    );
  });

  test('traduce 401 a UnauthorizedFailure y 422 a ValidationFailure', () async {
    final unauthorized = _clientWith(
      (_) async =>
          _json(<String, Object?>{'code': 'UNAUTHENTICATED'}, statusCode: 401),
    );
    final invalid = _clientWith(
      (_) async => _json(<String, Object?>{
        'code': 'VALIDATION_ERROR',
        'message': 'Datos inválidos',
      }, statusCode: 422),
    );

    await expectLater(
      unauthorized.getJson('/api/v1/auth/me'),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.failure,
          'failure',
          isA<UnauthorizedFailure>(),
        ),
      ),
    );
    await expectLater(
      invalid.postJson('/api/v1/public/otp/request'),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.failure,
          'failure',
          isA<ValidationFailure>(),
        ),
      ),
    );
  });

  test('traduce una caída de red a NetworkFailure', () async {
    final client = _clientWith((options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    });

    await expectLater(
      client.getJson('/api/v1/public/tenant'),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      ),
    );
  });

  test('la clave de idempotencia es única', () {
    final generator = SecureIdempotencyKeyGenerator();
    final keys = <String>{for (var i = 0; i < 100; i++) generator.generate()};

    expect(keys, hasLength(100));
    expect(keys.every((key) => key.startsWith('idem-')), isTrue);
  });
}
