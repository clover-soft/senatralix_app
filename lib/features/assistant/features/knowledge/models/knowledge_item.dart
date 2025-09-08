import 'package:flutter/foundation.dart';

/// Статус обработки источника знаний (моки)
enum KnowledgeStatus { processing, ready, error }

/// Модель элемента базы знаний
@immutable
class KnowledgeBaseItem {
  final int id;
  final String externalId;
  final String markdown;
  final KnowledgeStatus status;
  final bool active; // активирован для ассистента

  // Настройки индексации
  final int maxChunkSizeTokens;
  final int chunkOverlapTokens;
  final int ttlDays;
  final String expirationPolicy; // e.g. "since_last_active"

  final DateTime createdAt;
  final DateTime updatedAt;

  const KnowledgeBaseItem({
    required this.id,
    required this.externalId,
    required this.markdown,
    required this.status,
    required this.active,
    required this.maxChunkSizeTokens,
    required this.chunkOverlapTokens,
    required this.ttlDays,
    required this.expirationPolicy,
    required this.createdAt,
    required this.updatedAt,
  });

  KnowledgeBaseItem copyWith({
    int? id,
    String? externalId,
    String? markdown,
    KnowledgeStatus? status,
    bool? active,
    int? maxChunkSizeTokens,
    int? chunkOverlapTokens,
    int? ttlDays,
    String? expirationPolicy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => KnowledgeBaseItem(
        id: id ?? this.id,
        externalId: externalId ?? this.externalId,
        markdown: markdown ?? this.markdown,
        status: status ?? this.status,
        active: active ?? this.active,
        maxChunkSizeTokens: maxChunkSizeTokens ?? this.maxChunkSizeTokens,
        chunkOverlapTokens: chunkOverlapTokens ?? this.chunkOverlapTokens,
        ttlDays: ttlDays ?? this.ttlDays,
        expirationPolicy: expirationPolicy ?? this.expirationPolicy,
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

  factory KnowledgeBaseItem.fromJson(Map<String, dynamic> json) => KnowledgeBaseItem(
        id: int.tryParse('${json['id']}') ?? 0,
        externalId: json['external_id'] as String? ?? '',
        markdown: json['markdown'] as String? ?? '',
        status: _statusFromString(json['status'] as String? ?? 'ready'),
        active: json['active'] as bool? ?? true,
        maxChunkSizeTokens: int.tryParse('${json['settings']?['max_chunk_size_tokens']}') ?? 700,
        chunkOverlapTokens: int.tryParse('${json['settings']?['chunk_overlap_tokens']}') ?? 300,
        ttlDays: int.tryParse('${json['settings']?['ttl_days']}') ?? 30,
        expirationPolicy: json['settings']?['expiration_policy'] as String? ?? 'since_last_active',
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
          'ttl_days': ttlDays,
          'expiration_policy': expirationPolicy,
        },
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
