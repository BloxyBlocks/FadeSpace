import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Abstracción mínima del transporte WebSocket (permite pruebas sin red).
abstract interface class RealtimeTransport {
  Stream<String> get messages;

  void send(String message);

  Future<void> close();
}

/// Transporte WebSocket real.
final class WebSocketRealtimeTransport implements RealtimeTransport {
  new(Uri uri) : _channel = WebSocketChannel.connect(uri);

  final WebSocketChannel _channel;

  @override
  Stream<String> get messages => _channel.stream.map((dynamic message) {
    if (message is String) {
      return message;
    }

    if (message is List<int>) {
      return utf8.decode(message);
    }

    return message.toString();
  });

  @override
  void send(String message) => _channel.sink.add(message);

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}
