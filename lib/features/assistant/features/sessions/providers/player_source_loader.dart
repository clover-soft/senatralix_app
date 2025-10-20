import 'package:just_audio/just_audio.dart';
import 'player_source_loader_io.dart' if (dart.library.html) 'player_source_loader_web.dart' as impl;

class BuiltSource {
  final UriAudioSource source;
  final Future<void> Function()? cleanup;
  const BuiltSource({required this.source, this.cleanup});
}

Future<BuiltSource> buildAudioUriSource(
  String url, {
  Map<String, String>? headers,
  bool withCredentials = false,
}) =>
    impl.buildAudioUriSource(url, headers: headers, withCredentials: withCredentials);
