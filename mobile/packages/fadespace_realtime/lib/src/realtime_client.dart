import 'dart:async';
import 'dart:convert';

import 'package:fadespace_realtime/src/realtime_config.dart';
import 'package:fadespace_realtime/src/realtime_event.dart';
import 'package:fadespace_realtime/src/realtime_transport.dart';

/// Estado visible de la conexión (RNF-15: degradación segura).
enum RealtimeConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

typedef RealtimeTransportFactory = RealtimeTransport Function(Uri uri);

/// Autoriza un canal privado y devuelve `auth` (y `channel_data` si aplica).
typedef ChannelAuthorizer = Future<Map<String, String>> Function(
  String channel,
  String socketId,
);

/// Cliente del protocolo Pusher que habla con Laravel Reverb.
///
/// Implementa reconexión con *backoff* exponencial y resincronización de las
/// suscripciones existentes; los canales privados se autorizan contra el API.
final class ReverbClient {
  new({
    required this.config,
    RealtimeTransportFactory? transportFactory,
    this.channelAuthorizer,
  }) : _transportFactory = transportFactory ?? WebSocketRealtimeTransport.new;

  final RealtimeConfig config;
  final ChannelAuthorizer? channelAuthorizer;
  final RealtimeTransportFactory _transportFactory;

  final _events = StreamController<RealtimeEvent>.broadcast();
  final _states = StreamController<RealtimeConnectionState>.broadcast();
  final Set<String> _subscriptions = <String>{};

  RealtimeTransport? _transport;
  StreamSubscription<String>? _messages;
  Timer? _reconnectTimer;
  String? _socketId;
  int _reconnectAttempts = 0;
  RealtimeConnectionState _state = RealtimeConnectionState.disconnected;
  bool _manualClose = false;
  bool _disposed = false;

  Stream<RealtimeEvent> get events => _events.stream;

  Stream<RealtimeConnectionState> get connectionStates => _states.stream;

  RealtimeConnectionState get state => _state;

  String? get socketId => _socketId;

  Future<void> connect() async {
    if (_disposed ||
        _state == RealtimeConnectionState.connecting ||
        _state == RealtimeConnectionState.connected) {
      return;
    }

    _manualClose = false;
    _setState(
      _reconnectAttempts == 0
          ? RealtimeConnectionState.connecting
          : RealtimeConnectionState.reconnecting,
    );

    try {
      final transport = _transportFactory(_buildUri());
      _transport = transport;
      _messages = transport.messages.listen(
        _handleMessage,
        onError: (Object _) => _handleDisconnection(),
        onDone: _handleDisconnection,
      );
    } on Object {
      _handleDisconnection();
    }
  }

  Future<void> subscribe(String channel) async {
    _subscriptions.add(channel);

    if (_state != RealtimeConnectionState.connected || _socketId == null) {
      return;
    }

    await _sendSubscription(channel);
  }

  Future<void> unsubscribe(String channel) async {
    _subscriptions.remove(channel);

    if (_state == RealtimeConnectionState.connected) {
      _send(<String, Object?>{
        'event': 'pusher:unsubscribe',
        'data': <String, Object?>{'channel': channel},
      });
    }
  }

  Future<void> disconnect() async {
    _manualClose = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _messages?.cancel();
    _messages = null;

    final transport = _transport;
    _transport = null;
    await transport?.close();

    _socketId = null;
    _reconnectAttempts = 0;
    _setState(RealtimeConnectionState.disconnected);
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    await _events.close();
    await _states.close();
  }

  void _handleMessage(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return;
    }

    if (decoded is! Map<String, dynamic>) {
      return;
    }

    final event = decoded['event'];
    if (event is! String) {
      return;
    }

    switch (event) {
      case 'pusher:connection_established':
        final payload = _decodePayload(decoded['data']);
        final socketId = payload['socket_id'];
        if (socketId is String) {
          _socketId = socketId;
        }
        _reconnectAttempts = 0;
        _setState(RealtimeConnectionState.connected);
        unawaited(_resubscribeAll());
      case 'pusher:ping':
        _send(<String, Object?>{
          'event': 'pusher:pong',
          'data': <String, Object?>{},
        });
      case 'pusher:error':
        _handleDisconnection();
      default:
        if (event.startsWith('pusher')) {
          return;
        }

        final channel = decoded['channel'];
        _events.add(
          RealtimeEvent(
            channel: channel is String ? channel : '',
            name: event,
            data: _decodePayload(decoded['data']),
          ),
        );
    }
  }

  Future<void> _resubscribeAll() async {
    for (final channel in _subscriptions) {
      try {
        await _sendSubscription(channel);
      } on Object {
        // Un fallo de autorización no debe tumbar la conexión; se reintenta
        // al reconectar o cuando la app vuelva a suscribirse.
      }
    }
  }

  Future<void> _sendSubscription(String channel) async {
    final payload = <String, Object?>{'channel': channel};

    if (channel.startsWith('private-') || channel.startsWith('presence-')) {
      final authorizer = channelAuthorizer;
      final socketId = _socketId;
      if (authorizer == null || socketId == null) {
        throw StateError('Se requiere autorización para el canal $channel');
      }

      payload.addAll(await authorizer(channel, socketId));
    }

    _send(<String, Object?>{'event': 'pusher:subscribe', 'data': payload});
  }

  void _handleDisconnection() {
    _socketId = null;

    final subscription = _messages;
    _messages = null;
    unawaited(subscription?.cancel());

    final transport = _transport;
    _transport = null;
    if (transport != null) {
      unawaited(transport.close());
    }

    if (_manualClose || _disposed) {
      _setState(RealtimeConnectionState.disconnected);
      return;
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    _setState(RealtimeConnectionState.reconnecting);

    final exponent = _reconnectAttempts - 1;
    final factor = 1 << (exponent > 5 ? 5 : exponent);
    final millis = config.initialReconnectDelay.inMilliseconds * factor;
    final delay = Duration(
      milliseconds: millis > config.maxReconnectDelay.inMilliseconds
          ? config.maxReconnectDelay.inMilliseconds
          : millis,
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      unawaited(connect());
    });
  }

  void _send(Map<String, Object?> message) {
    _transport?.send(jsonEncode(message));
  }

  void _setState(RealtimeConnectionState state) {
    if (_state == state || _disposed) {
      return;
    }

    _state = state;
    _states.add(state);
  }

  Map<String, Object?> _decodePayload(Object? raw) {
    var decoded = raw;

    if (raw is String) {
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        return <String, Object?>{'value': raw};
      }
    }

    if (decoded is Map) {
      return decoded.map<String, Object?>(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return <String, Object?>{};
  }

  Uri _buildUri() {
    final base = Uri.parse(config.wsUrl);
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;

    return base.replace(
      path: '$basePath/app/${config.appKey}',
      queryParameters: <String, String>{
        ...base.queryParameters,
        'protocol': '7',
        'client': 'fadespace-flutter',
        'version': config.clientVersion,
        'flash': 'false',
      },
    );
  }
}
