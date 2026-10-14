import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deltasync/deltasync.dart';

/// Loopback-only technical example. USB routing connects two fixed peers.
/// No authentication or production protocol is provided by this helper.
class HttpPeerLink implements AcknowledgingDeltaTransport {
  HttpPeerLink({required this.peerReplicaId, required this.peerUri});

  @override
  final String peerReplicaId;
  Uri peerUri;
  final _client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  HttpServer? _server;
  Future<void>? _serving;

  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();

  /// Start after restoration. Only the engine validates and commits envelopes.
  Future<int> listen(
    SyncEngine engine, {
    int port = 8092,
    required Future<Map<String, Object?>> Function() report,
  }) async {
    if (_server != null) throw StateError('Peer listener already started');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server = server;
    _serving = _serve(server, engine, report);
    return server.port;
  }

  Future<void> _serve(
    HttpServer server,
    SyncEngine engine,
    Future<Map<String, Object?>> Function() report,
  ) async {
    await for (final request in server) {
      try {
        Object result;
        if (request.method == 'POST' && request.uri.path == '/delta') {
          final json = jsonDecode(await utf8.decoder.bind(request).join());
          if (json is! Map<String, dynamic>) {
            throw const FormatException('Envelope object required');
          }
          final ack = await engine.receiveEnvelope(
            DeltaEnvelope.fromJson(json),
          );
          result = ack.toJson();
        } else if (request.method == 'GET' && request.uri.path == '/state') {
          // Inspect only when actions are idle; durable proof uses closed SQLite.
          result = await report();
        } else {
          request.response.statusCode = HttpStatus.notFound;
          result = {'error': 'Unknown lab route'};
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(result));
      } catch (error) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write(jsonEncode({'error': error.toString()}));
      } finally {
        await request.response.close();
      }
    }
  }

  @override
  Future<void> send(DeltaEnvelope envelope) async {
    await sendAndAwaitAck(envelope);
  }

  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async {
    final request = await _client
        .postUrl(peerUri.resolve('/delta'))
        .timeout(const Duration(seconds: 5));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(envelope.toJson()));
    final response = await request.close().timeout(const Duration(seconds: 5));
    final body = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}: $body');
    }
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('ACK object required');
    }
    return DeltaAcknowledgement.fromJson(json);
  }

  Future<void> close() async {
    _client.close(force: true);
    await _server?.close(force: true);
    await _serving;
  }
}
