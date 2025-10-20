// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<void> saveRecording(
  String url, {
  String? suggestedFileName,
}) async {
  // На Web выполняем запрос с учётом cookies (withCredentials), получаем Blob и скачиваем.
  // Это надёжнее в проде, где требуется авторизация, чем прямая ссылка без заголовков.
  final fileName = (suggestedFileName?.trim().isNotEmpty == true)
      ? suggestedFileName!.trim()
      : 'recording_${DateTime.now().millisecondsSinceEpoch}.mp3';

  // Выполняем XHR с withCredentials, чтобы браузер приложил cookies домена API.
  final req = await html.HttpRequest.request(
    url,
    method: 'GET',
    withCredentials: true,
    responseType: 'blob',
  );

  final blob = req.response as html.Blob?;
  if (blob == null) {
    throw StateError('Не удалось получить файл: пустой ответ');
  }

  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  try {
    final anchor = html.AnchorElement(href: objectUrl)
      ..download = fileName
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } finally {
    // Освобождаем URL, когда он больше не нужен
    html.Url.revokeObjectUrl(objectUrl);
  }
}
