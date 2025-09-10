import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_item.dart';

/// Состояние редактора KnowledgeBaseItem
class KnowledgeEditState {
  KnowledgeEditState({
    required this.name,
    required this.description,
    required this.externalId,
    required this.markdown,
    required this.maxChunkSizeTokens,
    required this.chunkOverlapTokens,
  });

  final String name;
  final String description;
  final String externalId;
  final String markdown;
  final int maxChunkSizeTokens;
  final int chunkOverlapTokens;

  KnowledgeEditState copy({
    String? name,
    String? description,
    String? externalId,
    String? markdown,
    int? maxChunkSizeTokens,
    int? chunkOverlapTokens,
  }) => KnowledgeEditState(
        name: name ?? this.name,
        description: description ?? this.description,
        externalId: externalId ?? this.externalId,
        markdown: markdown ?? this.markdown,
        maxChunkSizeTokens: maxChunkSizeTokens ?? this.maxChunkSizeTokens,
        chunkOverlapTokens: chunkOverlapTokens ?? this.chunkOverlapTokens,
      );

  static KnowledgeEditState fromItem(KnowledgeBaseItem item) => KnowledgeEditState(
        name: item.name,
        description: item.description,
        externalId: item.externalId,
        markdown: item.markdown,
        maxChunkSizeTokens: item.maxChunkSizeTokens,
        chunkOverlapTokens: item.chunkOverlapTokens,
      );
}
