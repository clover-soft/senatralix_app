import 'package:flutter/foundation.dart';

/// Статус обработки источника знаний (моки)
enum KnowledgeStatus { processing, ready, error }

/// Модель элемента базы знаний
@immutable
class KnowledgeBaseItem {
  final int id;
  final String name;
  final String description;
  final String externalId;
  final String markdown;
  final KnowledgeStatus status;
  final bool active; // активирован для ассистента

  // Настройки индексации
  final int maxChunkSizeTokens;
  final int chunkOverlapTokens;

  final DateTime createdAt;
  final DateTime updatedAt;

  const KnowledgeBaseItem({
    required this.id,
    required this.name,
    required this.description,
    required this.externalId,
    required this.markdown,
    required this.status,
    required this.active,
    required this.maxChunkSizeTokens,
    required this.chunkOverlapTokens,
    required this.createdAt,
    required this.updatedAt,
  });

  KnowledgeBaseItem copyWith({
    int? id,
    String? name,
    String? description,
    String? externalId,
    String? markdown,
    KnowledgeStatus? status,
    bool? active,
    int? maxChunkSizeTokens,
    int? chunkOverlapTokens,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => KnowledgeBaseItem(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    externalId: externalId ?? this.externalId,
    markdown: markdown ?? this.markdown,
    status: status ?? this.status,
    active: active ?? this.active,
    maxChunkSizeTokens: maxChunkSizeTokens ?? this.maxChunkSizeTokens,
    chunkOverlapTokens: chunkOverlapTokens ?? this.chunkOverlapTokens,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static KnowledgeStatus _statusFromString(String s) {
    switch (s) {
      case 'processing':
        return KnowledgeStatus.processing;
      case 'ready':
        return KnowledgeStatus.ready;
      case 'error':
        return KnowledgeStatus.error;
      default:
        return KnowledgeStatus.ready;
    }
  }

  static String _statusToString(KnowledgeStatus s) {
    switch (s) {
      case KnowledgeStatus.processing:
        return 'processing';
      case KnowledgeStatus.ready:
        return 'ready';
      case KnowledgeStatus.error:
        return 'error';
    }
  }

  factory KnowledgeBaseItem.fromJson(Map<String, dynamic> json) =>
      KnowledgeBaseItem(
        id: int.tryParse('${json['id']}') ?? 0,
        name:
            (json['settings'] is Map &&
                (json['settings'] as Map).containsKey('name'))
            ? (json['settings']['name'] as String? ?? '')
            : (json['name'] as String? ?? ''),
        description:
            (json['settings'] is Map &&
                (json['settings'] as Map).containsKey('description'))
            ? (json['settings']['description'] as String? ?? '')
            : (json['description'] as String? ?? ''),
        externalId: json['external_id'] as String? ?? '',
        markdown: json['markdown'] as String? ?? '',
        status: _statusFromString(json['status'] as String? ?? 'ready'),
        active: json['active'] as bool? ?? true,
        maxChunkSizeTokens:
            int.tryParse('${json['settings']?['max_chunk_size_tokens']}') ??
            700,
        chunkOverlapTokens:
            int.tryParse('${json['settings']?['chunk_overlap_tokens']}') ?? 300,
        createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
        updatedAt: DateTime.tryParse('${json['updated_at']}') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'external_id': externalId,
    'markdown': markdown,
    'status': _statusToString(status),
    'active': active,
    'settings': {
      'max_chunk_size_tokens': maxChunkSizeTokens,
      'chunk_overlap_tokens': chunkOverlapTokens,
      'name': name,
      'description': description,
    },
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
