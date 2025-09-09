import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_item.dart';

/// Состояние редактора KnowledgeBaseItem
class KnowledgeEditState {
  KnowledgeEditState({
    required this.externalId,
    required this.markdown,
    required this.maxChunkSizeTokens,
    required this.chunkOverlapTokens,
    required this.ttlDays,
    required this.expirationPolicy,
  });

  final String externalId;
  final String markdown;
  final int maxChunkSizeTokens;
  final int chunkOverlapTokens;
  final int ttlDays;
  final String expirationPolicy;

  KnowledgeEditState copy({
    String? externalId,
    String? markdown,
    int? maxChunkSizeTokens,
    int? chunkOverlapTokens,
    int? ttlDays,
    String? expirationPolicy,
  }) => KnowledgeEditState(
        externalId: externalId ?? this.externalId,
        markdown: markdown ?? this.markdown,
        maxChunkSizeTokens: maxChunkSizeTokens ?? this.maxChunkSizeTokens,
        chunkOverlapTokens: chunkOverlapTokens ?? this.chunkOverlapTokens,
        ttlDays: ttlDays ?? this.ttlDays,
        expirationPolicy: expirationPolicy ?? this.expirationPolicy,
      );

  static KnowledgeEditState fromItem(KnowledgeBaseItem item) => KnowledgeEditState(
        externalId: item.externalId,
        markdown: item.markdown,
        maxChunkSizeTokens: item.maxChunkSizeTokens,
        chunkOverlapTokens: item.chunkOverlapTokens,
        ttlDays: item.ttlDays,
        expirationPolicy: item.expirationPolicy,
      );
}
