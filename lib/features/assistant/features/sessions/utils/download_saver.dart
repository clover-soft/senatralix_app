import 'download_saver_io.dart' if (dart.library.html) 'download_saver_web.dart' as impl;

/// Сохранение аудиофайла по URL.
Future<void> saveRecording(
  String url, {
  String? suggestedFileName,
}) =>
    impl.saveRecording(url, suggestedFileName: suggestedFileName);
