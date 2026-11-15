/// Evento recibido por un canal de tiempo real.
final class RealtimeEvent {
  const new({required this.channel, required this.name, required this.data});

  final String channel;

  /// Nombre del evento (`realtime.probe`, `AppointmentConfirmed`, …).
  final String name;

  final Map<String, Object?> data;

  @override
  String toString() => 'RealtimeEvent($channel, $name, $data)';
}
