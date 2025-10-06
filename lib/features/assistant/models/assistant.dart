// Модель ассистента
import 'package:sentralix_app/features/assistant/models/assistant_settings.dart';

class Assistant {
  final String id;
  final String name;
  final String? description;
  final AssistantSettings? settings; // настройки ассистента (опционально)
  /// Идентификатор связанного сценария диалога (если задан на бэкенде)
  final int? dialogId;

  const Assistant({
    required this.id,
    required this.name,
    this.description,
    this.settings,
    this.dialogId,
  });

  Assistant copyWith({
    String? id,
    String? name,
    String? description,
    AssistantSettings? settings,
    int? dialogId,
  }) => Assistant(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    settings: settings ?? this.settings,
    dialogId: dialogId ?? this.dialogId,
  );
}
