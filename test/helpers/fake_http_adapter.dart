import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A stand-in for the network behind a [Dio]: it answers each request with
/// the next of [replies], a `(status, body)` record answered as JSON or
/// anything else thrown as the network's error, and keeps the [requests]
/// it was sent.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(List<Object> replies) : _replies = [...replies];

  final List<Object> _replies;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    // Everything sent is read, as the network would.
    await requestStream?.drain<void>();
    final reply = _replies.removeAt(0);
    if (reply case (final int status, final Object? body)) {
      return ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    throw reply;
  }

  @override
  void close({bool force = false}) {}
}
