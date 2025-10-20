// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<void> saveRecording(
  String url, {
  String? suggestedFileName,
}) async {
  // На Web используем прямое скачивание через <a download href="...">
  final anchor = html.AnchorElement(href: url)
    ..download = (suggestedFileName?.trim().isNotEmpty == true)
        ? suggestedFileName!.trim()
        : 'recording_${DateTime.now().millisecondsSinceEpoch}.mp3'
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
