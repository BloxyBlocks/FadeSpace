import 'dart:async';
import 'dart:convert';

import 'package:fadespace_realtime/fadespace_realtime.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeTransport implements RealtimeTransport {
  final _controller = StreamController<String>();
  final sent = <String>[];

  @override
  Stream<String> get messages => _controller.stream;

  @override
  void send(String message) => sent.add(message);

  @override
  Future<void> close() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  void emit(Map<String, Object?> message) {
    _controller.add(jsonEncode(message));
  }
}

void main() {
  late List<_FakeTransport> transports;

  ReverbClient buildClient({
    ChannelAuthorizer? authorizer,
    Duration initialReconnectDelay = const Duration(milliseconds: 10),
  }) {
    transports = <_FakeTransport>[];

    return ReverbClient(
      config: RealtimeConfig(
        wsUrl: 'ws://localhost:8080',
        appKey: 'test-key',
        initialReconnectDelay: initialReconnectDelay,
        maxReconnectDelay: const Duration(milliseconds: 20),
      ),
      transportFactory: (uri) {
        final transport = _FakeTransport();
        transports.add(transport);
        return transport;
      },
      channelAuthorizer: authorizer,
    );
  }

  void establish(_FakeTransport transport, {String socketId = '123.456'}) {
    transport.emit(<String, Object?>{
      'event': 'pusher:connection_established',
      'data': jsonEncode(<String, Object?>{'socket_id': socketId}),
    });
  }

  test('conecta, se suscribe y decodifica eventos', () async {
    final client = buildClient();
    final events = <RealtimeEvent>[];
    final subscription = client.events.listen(events.add);
    addTearDown(() async {
      await subscription.cancel();
      await client.dispose();
    });

    await client.connect();
    expect(transports, hasLength(1));
    expect(client.state, RealtimeConnectionState.connecting);

    establish(transports.single);
    await Future<void>.delayed(Duration.zero);

    expect(client.state, RealtimeConnectionState.connected);
    expect(client.socketId, '123.456');

    await client.subscribe('tenant.demo');
    final subscribe =
        jsonDecode(transports.single.sent.last) as Map<String, Object?>;
    expect(subscribe['event'], 'pusher:subscribe');
    expect(
      (subscribe['data']! as Map<String, Object?>)['channel'],
      'tenant.demo',
    );
  });

  test('responde ping y conserva el evento de dominio', () async {
    final client = buildClient(
      authorizer: (_, _) async => <String, String>{'auth': 'k:s'},
    );
    addTearDown(client.dispose);
    final events = <RealtimeEvent>[];
    final subscription = client.events.listen(events.add);
    addTearDown(subscription.cancel);

    await client.connect();
    establish(transports.single);
    await Future<void>.delayed(Duration.zero);

    transports.single.emit(<String, Object?>{'event': 'pusher:ping'});
    await Future<void>.delayed(Duration.zero);

    final pong =
        jsonDecode(transports.single.sent.last) as Map<String, Object?>;
    expect(pong['event'], 'pusher:pong');

    transports.single.emit(<String, Object?>{
      'event': 'realtime.probe',
      'channel': 'fadespace.probe',
      'data': jsonEncode(<String, Object?>{
        'emitted_at': '2026-11-14T12:00:00.123456Z',
        'sequence': 1,
      }),
    });
    await Future<void>.delayed(Duration.zero);

    expect(events.single.name, 'realtime.probe');
    expect(events.single.channel, 'fadespace.probe');
    expect(events.single.data['sequence'], 1);
  });

  test('autoriza canales privados con el socket id actual', () async {
    String? authorizedChannel;
    String? authorizedSocket;
    final client = buildClient(
      authorizer: (channel, socketId) async {
        authorizedChannel = channel;
        authorizedSocket = socketId;
        return <String, String>{'auth': 'key:signature'};
      },
    );
    addTearDown(client.dispose);

    await client.connect();
    establish(transports.single, socketId: '999.888');
    await Future<void>.delayed(Duration.zero);

    await client.subscribe('private-tenant.1.barber.7');

    expect(authorizedChannel, 'private-tenant.1.barber.7');
    expect(authorizedSocket, '999.888');

    final subscribe =
        jsonDecode(transports.single.sent.last) as Map<String, Object?>;
    expect(
      (subscribe['data']! as Map<String, Object?>)['auth'],
      'key:signature',
    );
  });

  test('reconecta y vuelve a suscribir los canales existentes', () async {
    final client = buildClient(
      authorizer: (_, _) async => <String, String>{'auth': 'k:s'},
    );
    addTearDown(client.dispose);

    await client.connect();
    establish(transports.single);
    await Future<void>.delayed(Duration.zero);
    await client.subscribe('private-tenant.1.admin');

    await transports.single.close();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(transports, hasLength(2));
    expect(client.state, RealtimeConnectionState.reconnecting);

    establish(transports.last, socketId: 'new-socket');
    await Future<void>.delayed(Duration.zero);

    expect(client.state, RealtimeConnectionState.connected);

    final resubscribe =
        jsonDecode(transports.last.sent.last) as Map<String, Object?>;
    expect(resubscribe['event'], 'pusher:subscribe');
    expect(
      (resubscribe['data']! as Map<String, Object?>)['channel'],
      'private-tenant.1.admin',
    );
  });
}
