import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Mide la latencia servidor → cliente del protocolo Pusher de Reverb.
///
/// Uso:
///   dart run tool/latency_probe.dart \
///     --url=ws://127.0.0.1:8080 --key=fadespace-local-key \
///     --duration=15 --output=../../spikes/t008/latency.json
Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  final url = options['url'] ?? 'ws://127.0.0.1:8080';
  final key = options['key'] ?? 'fadespace-local-key';
  final duration = Duration(
    seconds: int.tryParse(options['duration'] ?? '15') ?? 15,
  );
  final output = options['output'];

  final socketUri = Uri.parse('$url/app/$key').replace(
    queryParameters: <String, String>{
      'protocol': '7',
      'client': 'fadespace-latency-probe',
      'version': '0.1.0',
    },
  );

  final channel = WebSocketChannel.connect(socketUri);
  await channel.ready;

  final samples = <Map<String, Object?>>[];
  var expectedProbeId = options['probe'];
  var finished = false;

  final subscription = channel.stream.listen((raw) {
    final decoded = _decode(raw);
    final event = decoded['event'];

    if (event == 'pusher:connection_established') {
      final payload = _decode(decoded['data']);
      final socketId = payload['socket_id'];
      if (socketId is String) {
        channel.sink.add(
          jsonEncode(<String, Object?>{
            'event': 'pusher:subscribe',
            'data': <String, Object?>{'channel': 'fadespace.probe'},
          }),
        );
      }
      return;
    }

    if (event == 'pusher:ping') {
      channel.sink.add(
        jsonEncode(<String, Object?>{
          'event': 'pusher:pong',
          'data': <String, Object?>{},
        }),
      );
      return;
    }

    if (event != 'realtime.probe') {
      return;
    }

    final data = _decode(decoded['data']);
    final emittedAt = data['emitted_at'];
    final probeId = data['probe_id'];
    final sequence = data['sequence'];

    if (emittedAt is! String) {
      return;
    }

    expectedProbeId ??= probeId is String ? probeId : null;

    if (probeId is String &&
        expectedProbeId != null &&
        probeId != expectedProbeId) {
      return;
    }

    final receivedAt = DateTime.now().toUtc();
    final emitted = DateTime.parse(emittedAt).toUtc();
    final latencyMs = receivedAt.difference(emitted).inMicroseconds / 1000;

    samples.add(<String, Object?>{
      'sequence': sequence,
      'latency_ms': double.parse(latencyMs.toStringAsFixed(3)),
      'received_at': receivedAt.toIso8601String(),
    });
  });

  final stopTimer = Timer(duration, () {
    finished = true;
  });

  while (!finished) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  await subscription.cancel();
  stopTimer.cancel();
  await channel.sink.close();

  final latencies =
      samples
          .map((sample) => (sample['latency_ms']! as num).toDouble())
          .toList()
        ..sort();

  final summary = <String, Object?>{
    'transport': 'reverb-pusher-protocol',
    'url': url,
    'probe_id': expectedProbeId,
    'measurement': 'received_at_utc - emitted_at_utc',
    'samples_received': samples.length,
    'p50_ms': _percentile(latencies, 0.50),
    'p95_ms': _percentile(latencies, 0.95),
    'min_ms': latencies.isEmpty ? null : latencies.first,
    'max_ms': latencies.isEmpty ? null : latencies.last,
    'samples': samples,
  };

  final encoded = const JsonEncoder.withIndent('  ').convert(summary);
  stdout.writeln(encoded);

  if (output != null) {
    final file = File(output);
    await file.parent.create(recursive: true);
    await file.writeAsString('$encoded\n');
  }
}

Map<String, String> _parseArgs(List<String> args) {
  final options = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--')) {
      continue;
    }
    final separator = arg.indexOf('=');
    if (separator == -1) {
      options[arg.substring(2)] = 'true';
    } else {
      options[arg.substring(2, separator)] = arg.substring(separator + 1);
    }
  }
  return options;
}

Map<String, Object?> _decode(Object? raw) {
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

double? _percentile(List<double> sorted, double percentile) {
  if (sorted.isEmpty) {
    return null;
  }
  final index = ((sorted.length - 1) * percentile).round();
  return double.parse(sorted[min(index, sorted.length - 1)].toStringAsFixed(3));
}
