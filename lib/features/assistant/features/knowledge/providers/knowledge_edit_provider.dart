import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_edit_state.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_item.dart';

class KnowledgeEditController extends StateNotifier<KnowledgeEditState> {
  KnowledgeEditController(KnowledgeBaseItem initial)
      : super(KnowledgeEditState.fromItem(initial));

  void setName(String v) => state = state.copy(name: v);
  void setDescription(String v) => state = state.copy(description: v);
  void setExternalId(String v) => state = state.copy(externalId: v);
  void setMarkdown(String v) => state = state.copy(markdown: v);
  void setMaxChunk(int v) => state = state.copy(maxChunkSizeTokens: v);
  void setOverlap(int v) => state = state.copy(chunkOverlapTokens: v);

  KnowledgeBaseItem buildResult(KnowledgeBaseItem initial) => initial.copyWith(
        name: state.name.trim(),
        description: state.description.trim(),
        externalId: state.externalId.trim(),
        markdown: state.markdown,
        maxChunkSizeTokens: state.maxChunkSizeTokens,
        chunkOverlapTokens: state.chunkOverlapTokens,
        updatedAt: DateTime.now(),
      );
}

final knowledgeEditProvider = StateNotifierProvider.autoDispose
    .family<KnowledgeEditController, KnowledgeEditState, KnowledgeBaseItem>((ref, initial) {
  return KnowledgeEditController(initial);
});
