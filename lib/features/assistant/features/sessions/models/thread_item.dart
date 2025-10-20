// Модель треда ассистента
// Комментарии и импорты по правилам проекта

class ThreadItem {
  final int id;
  final int assistantId;
  final String? externalId;
  final String internalId;
  final String title;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ThreadItem({
    required this.id,
    required this.assistantId,
    required this.externalId,
    required this.internalId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ThreadItem.fromJson(Map<String, dynamic> json) {
    return ThreadItem(
      id: json['id'] as int,
      assistantId: json['assistant_id'] as int,
      externalId: json['external_id'] as String?,
      internalId: json['internal_id'] as String,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: (json['updated_at'] as String?) != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
