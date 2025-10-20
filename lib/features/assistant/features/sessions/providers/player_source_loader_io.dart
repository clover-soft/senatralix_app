import 'dart:async';
import 'package:just_audio/just_audio.dart';

import 'player_source_loader.dart';

Future<BuiltSource> buildAudioUriSource(
  String url, {
  Map<String, String>? headers,
  bool withCredentials = false, // игнорируется на native
}) async {
  final src = AudioSource.uri(Uri.parse(url), headers: headers);
  return BuiltSource(source: src);
}
