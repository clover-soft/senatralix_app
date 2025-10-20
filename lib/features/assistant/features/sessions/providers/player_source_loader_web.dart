// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';
import 'package:just_audio/just_audio.dart';

import 'player_source_loader.dart';

Future<BuiltSource> buildAudioUriSource(
  String url, {
  Map<String, String>? headers,
  bool withCredentials = false,
}) async {
  final bytes = await _downloadBytes(
    url,
    headers: headers,
    withCredentials: withCredentials,
  );
  final blob = html.Blob([bytes], 'audio/mpeg');
  final objectUrl = html.Url.createObjectUrl(blob);
  Future<void> cleanup() async {
    html.Url.revokeObjectUrl(objectUrl);
  }

  final src = AudioSource.uri(Uri.parse(objectUrl));
  return BuiltSource(source: src, cleanup: cleanup);
}

Future<Uint8List> _downloadBytes(
  String url, {
  Map<String, String>? headers,
  bool withCredentials = false,
}) async {
  final resp = await html.HttpRequest.request(
    url,
    method: 'GET',
    responseType: 'arraybuffer',
    requestHeaders: headers,
    withCredentials: withCredentials,
  );
  // Статус проверки
  final status = resp.status;
  final finalUrl = resp.responseUrl ?? url;
  // print для наглядности в консоли браузера
  // ignore: avoid_print
  print('[BlobLoader] GET $finalUrl status=$status');
  if (status != 200) {
    throw StateError('HTTP $status loading $finalUrl');
  }
  final data = resp.response as ByteBuffer?;
  if (data == null || data.lengthInBytes == 0) {
    throw StateError('Empty response body for $finalUrl');
  }
  return Uint8List.view(data);
}
