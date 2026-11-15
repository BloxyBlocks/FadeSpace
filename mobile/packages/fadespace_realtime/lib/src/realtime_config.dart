/// Configuración de conexión al servidor Reverb.
final class RealtimeConfig {
  const new({
    required this.wsUrl,
    required this.appKey,
    this.clientVersion = '0.1.0',
    this.initialReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 30),
  });

  /// URL base, por ejemplo `ws://localhost:8080` o `wss://ws.fadespace.co`.
  final String wsUrl;

  /// Clave pública de la aplicación Reverb (`REVERB_APP_KEY`).
  final String appKey;

  final String clientVersion;

  final Duration initialReconnectDelay;

  final Duration maxReconnectDelay;
}
