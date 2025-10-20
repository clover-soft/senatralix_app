import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> saveRecording(
  String url, {
  String? suggestedFileName,
}) async {
  final dio = Dio();

  Directory baseDir;
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    final downloads = await getDownloadsDirectory();
    baseDir = downloads ?? await getApplicationDocumentsDirectory();
  } else {
    baseDir = await getApplicationDocumentsDirectory();
  }

  final fname = (suggestedFileName?.trim().isNotEmpty == true)
      ? suggestedFileName!.trim()
      : 'recording_${DateTime.now().millisecondsSinceEpoch}.mp3';
  final outPath = p.join(baseDir.path, fname);

  final resp = await dio.get<List<int>>(
    url,
    options: Options(responseType: ResponseType.bytes, followRedirects: true),
  );

  final file = File(outPath);
  await file.create(recursive: true);
  await file.writeAsBytes(resp.data ?? const <int>[]);
}
